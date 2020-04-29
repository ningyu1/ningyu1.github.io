---
toc : true
title : "zookeeper数据迁移及恢复"
description : "zookeeper数据迁移及恢复"
tags : [
	"zookeeper"
]
date : "2018-09-28 11:20:00"
categories : [
    "zookeeper"
]
menu : "main"
---

在做环境迁移的时候经常会遇到中间件的数据迁移，今天我们说一下zookeeper的数据如何迁移与恢复。

比如说我们使用prd环境数据迁移到st环境为例来叙述一下具体的步骤。

第一步：从prd环境zookeeper服务器的数据目录下复制最新的日志和快照文件。

先去zookeeper的安装目录下找到zookeeper的conf文件，例如：

```
$> cd /usr/local/zookeeper/conf
$> cat zoo.cfg
```

打开zoo.cfg文件找到具体配置的zookeeper的data目录，例如：

```
# the directory where the snapshot is stored.
# do not use /tmp for storage, /tmp here is just
# example sakes.
dataDir=/var/zookeeper
```

进入到dataDir下的version-2文件夹，version-2文件夹下存放的是zookeeper的日志和镜像文件，我们找到最新的日志和镜像文件，例如：

```
$> cd /var/zookeeper/version-2
$> ls -ah
-rw-r--r-- 1 zookeeper zookeeper 67108880 Sep 27 17:20 log.909e2d252
-rw-r--r-- 1 zookeeper zookeeper 10408329 Sep 27 17:01 snapshot.909e2d250
```

找到最新的日志和快照文件，例如上面的：log.909e2d252和snapshot.909e2d250

日志文件存放zookeeper全部数据记录 ，快照文件则是内存增量文件。

<span style="color:red">**ps.这里要注意找最新的日志和快照文件**</span>

zookeeper的日志和镜像文件的清理可以看这篇文章：[Zookeeper事务日志和snapshot清理方式](https://ningyu1.github.io/site/post/89-zookeeper-cleanlog/)

第二步：传输日志和快照文件

如果st和prd网络是通的话可以通过scp的方式复制过去，如果网络不通通过中转站来过渡。

第三步：停掉需要恢复数据的zk服务，删除数据目录下的文件，复制刚才的两个文件到数据目录下

假设需要恢复数据的服务器上zookeeper数据目录也是在/var/zookeeper下

```
$> rm -fr /var/zookeeper/*
$> cp log.909e2d252 snapshot.909e2d250 /var/zookeeper
$> cd /usr/local/zookeeper/bin
$> ./zkServer.sh start
```

如果是三台需要全部服务停掉，恢复其中的一台，然后等数据恢复完成后，再启动其余的两台服务让zk自己同步数据过去

第四步：验证数据是否真的恢复了

```
$> cd /usr/local/zookeeper/bin
$> ./zkCli.sh
$> ls /
```

ls查看zk中的数据.

Zookeeper日志与镜像文件的分析可以参考这篇文章：[ZooKeeper日志与快照文件简单分析](https://www.cnblogs.com/felixzh/p/8462740.html)