---
toc : true
title : "Trouble Shooting —— Enable AOF可能导致整个Redis被Block住，在3.0.6版本仍然存在"
description : "Redis Asynchronous AOF fsync is taking too long (disk is busy?)Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis."
tags : [
    "Redis",
	"AOF Block",
	"AOF",
	"Asynchronous AOF fsync is taking too long (disk is busy?)Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis",
	"调优"

]
date : "2017-10-09 09:53:36"
categories : [
    "Redis",
    "trouble shooting"
]
menu : "main"
---

## Redis会有短暂的几秒Block，应用报：Jedis connection failed, retrying...

这个问题现象是这样的，应用周期性的报：Jedis connection failed, retrying...，Redis开启AOF会被Block住导致无法连接，查看redis的日志

```
1486:M 09 Oct 09:33:18.072 * 10 changes in 300 seconds. Saving...
1486:M 09 Oct 09:33:18.075 * Background saving started by pid 20706
1486:M 09 Oct 09:33:34.011 * Asynchronous AOF fsync is taking too long (disk is busy?). Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis.
20706:C 09 Oct 09:33:42.629 * DB saved on disk
20706:C 09 Oct 09:33:42.630 * RDB: 178 MB of memory used by copy-on-write
1486:M 09 Oct 09:33:42.723 * Background saving terminated with success
```

重点：`Asynchronous AOF fsync is taking too long (disk is busy?). Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis.`

为什么每次写入磁盘会有disk is busy？这个问题？

网上有人写到：当AOF rewrite 15G大小的内存时，Redis整个死掉的样子，所有指令甚至包括slave发到master的ping，redis-cli info都不能被执行。

## 原因分析

[官方文档，由IO产生的Latency详细分析](http://www.redis.io/topics/latency), 已经预言了悲剧的发生，但一开始没留意。

Redis为求简单，采用了单请求处理线程结构。

打开AOF持久化功能后， Redis处理完每个事件后会调用write(2)将变化写入kernel的buffer，如果此时write(2)被阻塞，Redis就不能处理下一个事件。

Linux规定执行write(2)时，如果对同一个文件正在执行fdatasync(2)将kernel buffer写入物理磁盘，或者有system wide sync在执行，write(2)会被Block住，整个Redis被Block住。

如果系统IO繁忙，比如有别的应用在写盘，或者Redis自己在AOF rewrite或RDB snapshot(虽然此时写入的是另一个临时文件，虽然各自都在连续写，但两个文件间的切换使得磁盘磁头的寻道时间加长），就可能导致fdatasync(2)迟迟未能完成从而Block住write(2)，Block住整个Redis。

为了更清晰的看到fdatasync(2)的执行时长，可以使用"strace -p (pid of redis server) -T -e -f trace=fdatasync"，但会影响系统性能。

Redis提供了一个自救的方式，当发现文件有在执行fdatasync(2)时，就先不调用write(2)，只存在cache里，免得被Block。但如果已经超过两秒都还是这个样子，则会硬着头皮执行write(2)，即使redis会被Block住。

此时那句要命的log会打印：“Asynchronous AOF fsync is taking too long (disk is busy?). Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis.” 

之后用redis-cli INFO可以看到aof_delayed_fsync的值被加1。

因此，对于fsync设为everysec时丢失数据的可能性的最严谨说法是：如果有fdatasync在长时间的执行，此时redis意外关闭会造成文件里不多于两秒的数据丢失。

如果fdatasync运行正常，redis意外关闭没有影响，只有当操作系统crash时才会造成少于1秒的数据丢失。

## 影响版本

网上有说是在2.6.12版之前，但是我们使用的版本：redis_version:3.0.6 任然存在这个问题

## 解决方法

最后发现，原来是AOF rewrite时一直埋头的调用write(2)，由系统自己去触发sync。在RedHat Enterprise 6里，默认配置vm.dirty_background_ratio=10，也就是占用了10%的可用内存才会开始后台flush，而我的服务器有8G内存。

很明显一次flush太多数据会造成阻塞，所以最后果断设置了sysctl vm.dirty_bytes=33554432(32M)，问题解决。

然后提了个issue，[AOF rewrite时定时也执行一下fdatasync嘛](https://github.com/antirez/redis/issues/1019)， antirez回复新版中，AOF rewrite时32M就会重写主动调用fdatasync。


* 查看一下系统内核参数

```
>sysctl -a | grep dirty_background_ratio
vm.dirty_background_ratio = 10

>sysctl -a | grep vm.dirty_bytes
vm.dirty_bytes = 0
```

**ps.尝试修改一下**


* 编辑/etc/sysctl.conf

```
>vi /etc/sysctl.conf

## 在最后面增加
# 32M
vm.dirty_bytes=33554432

```

**ps.保存后下次启动会生效，下面是立即生效的修改方法：**

* 立即生效的修改方法

```
>sysctl vm.dirty_bytes=33554432
>sysctl -p
```

* 验证修改是否成功

```
>sysctl -a | grep vm.dirty_bytes
vm.dirty_bytes = 33554432
```

* 修改后redis下次RDB和AOF时的日志

```
1486:M 09 Oct 10:05:02.043 * 10 changes in 300 seconds. Saving...
1486:M 09 Oct 10:05:02.046 * Background saving started by pid 20987
20987:C 09 Oct 10:05:17.188 * DB saved on disk
20987:C 09 Oct 10:05:17.188 * RDB: 944 MB of memory used by copy-on-write
1486:M 09 Oct 10:05:17.274 * Background saving terminated with success
```

从redis的日志中发现已经没有了这句：`Asynchronous AOF fsync is taking too long (disk is busy?). Writing the AOF buffer without waiting for fsync to complete, this may slow down Redis.`

应用日志中也看不到：`Jedis connection failed, retrying...`异常

这个问题解决










