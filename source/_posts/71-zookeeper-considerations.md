---
toc : true
title : "Zookeeper常用命令与注意事项"
description : "Zookeeper常用命令与注意事项"
tags : [
	"zookeeper"
]
date : "2018-03-21 15:26:53"
categories : [
    "zookeeper"
]
menu : "main"
---

`Zookeeper`在互联网行业和分布式环境下是最常用的集群协调工具，那我们今天就对`Zookeeper`的常用命令和使用注意事项进一步说明，在这之前我们先看一下`Zookeeper`是什么，它能做什么？

# Zookeeper是什么？

`ZooKeeper`是一个开源的分布式应用程序协调服务，是`Google`的`Chubby`一个开源的实现，是`Hadoop`和Hbase的重要组件。它是一个为分布式应用提供一致性服务的软件，提供的功能包括：配置维护、域名服务、分布式同步、组服务等。

它的这些特性可以让我们在很多场景下使用它，可以用它做注册中心、分布式锁、选举、队列等。

# Zookeeper的原理

`ZooKeeper`是以`Fast Paxos`算法为基础的，[`Paxos` 算法](https://baike.baidu.com/item/Paxos%20%E7%AE%97%E6%B3%95)存在活锁的问题，即当有多个`proposer`交错提交时，有可能互相排斥导致没有一个`proposer`能提交成功，而`Fast Paxos`作了一些优化，通过选举产生一个`leader` (领导者)，只有`leader`才能提交`proposer`，具体算法可见`Fast Paxos`。因此，要想弄懂`ZooKeeper`首先得对`Fast Paxos`有所了解

`ZooKeeper`的基本运转流程：

1. 选举`Leader`。
2. 同步数据。
3. 选举`Leader`过程中算法有很多，但要达到的选举标准是一致的。
4. `Leader`要具有最高的执行`ID`，类似`root`权限。
5. 集群中大多数的机器得到响应并接受选出的`Leader`。

# Zookeeper数据结构

与普通的文件系统极其类似，如下：

![](/img/zookeeper/1.png)

其中每个节点称为一个znode. 每个znode由3部分组成:

* stat. 此为状态信息, 描述该znode的版本, 权限等信息.
* data. 与该znode关联的数据.
* children. 该znode下的子节点.


# Zookeeper节点类型

* `persistent`： `persistent`节点不和特定的`session`绑定, 不会随着创建该节点的`session`的结束而消失, 而是一直存在, 除非该节点被显式删除.
* `ephemeral`： `ephemeral`节点是临时性的, 如果创建该节点的`session`结束了, 该节点就会被自动删除. 	`ephemeral`节点不能拥有子节点. 虽然`ephemeral`节点与创建它的`session`绑定, 但只要该该节点没有被删除, 其他`session`就可以读写该节点中关联的数据. 使用`-e`参数指定创建`ephemeral`节点.
* `sequence`： 严格的说, `sequence`并非节点类型中的一种. `sequence`节点既可以是`ephemeral`的, 也可以是`persistent`的. 创建`sequence`节点时, `ZooKeeper server`会在指定的节点名称后加上一个数字序列, 该数字序列是递增的. 因此可以多次创建相同的`sequence`节点, 而得到不同的节点. 使用-s参数指定创建`sequence`节点.

# Zookeeper常用命令

## 启动服务

```
[app@iZbp1dijzcfg8m0bcqfv9yZ zookeeper]$ ./bin/zkServer.sh start
ZooKeeper JMX enabled by default
Using config: /usr/local/servers/zookeeper/zookeeper/bin/../conf/zoo.cfg
Starting zookeeper ... STARTED
```

## 查看当前zk节点状态

```
[zk@iZbp1dijzcfg8m0bcqfv9yZ bin]$ ./zkServer.sh status
JMX enabled by default
Using config: /usr/local/servers/zookeeper/zookeeper/bin/../conf/zoo.cfg
Mode: standalone
```

<span style="color:blue">ps. `standalone`代表单机模式，</span>

```
[zk@iZ23np2fk60Z bin]$ ./zkServer.sh status
JMX enabled by default
Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
Mode: leader
```

<span style="color:blue">ps. 集群模式下会显示的状态，`leader`节点，集群中其他机器会从leader节点同步数据</span>

```
[zk@iZ237ydkhyiZ bin]$ ./zkServer.sh status
JMX enabled by default
Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
Mode: follower
```

<span style="color:blue">ps. 集群模式下会显示的状态，`follower`节点在启动过程中会从leader节点同步所有数据</span>

## 连接服务

```
[app@iZbp1dijzcfg8m0bcqfv9yZ zookeeper]$ ./bin/zkCli.sh -server ip:port  
```

<span style="color:blue">ps. 不写ip端口默认连接本机服务.</span>

## 查看节点信息

```
[zk: localhost:2181(CONNECTED) 0] ls /
[seq, dubbo, disconf, otter, pinpoint-cluster, zookeeper]
```

## 查看指定node的子node

```
[zk: localhost:2181(CONNECTED) 3] ls /zookeeper
[quota]
```

## 创建一个普通节点

```
[zk: localhost:2181(CONNECTED) 6] create /hello world
Created /hello
```

## 获取hello节点的数据与状态

```
[zk: localhost:2181(CONNECTED) 8] get /hello
world
cZxid = 0x262ea76
ctime = Wed Mar 21 14:39:12 CST 2018
mZxid = 0x262ea76
mtime = Wed Mar 21 14:39:12 CST 2018
pZxid = 0x262ea76
cversion = 0
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 5
numChildren = 0
```

## 删除hello节点

```
[zk: localhost:2181(CONNECTED) 9] delete /hello
[zk: localhost:2181(CONNECTED) 10] get /hello
Node does not exist: /hello
```

<span style="color:blue">ps. 使用delete命令可以删除指定znode. 当该znode拥有子znode时, 必须先删除其所有子znode, 否则操作将失败. rmr命令可用于代替delete命令, rmr是一个递归删除命令, 如果发生指定节点拥有子节点时, rmr命令会首先删除子节点.</span>

## znode节点的状态信息

使用get命令获取指定节点的数据时, 同时也将返回该节点的状态信息, 称为Stat. 其包含如下字段:

* czxid. 节点创建时的zxid.
* mzxid. 节点最新一次更新发生时的zxid.
* ctime. 节点创建时的时间戳.
* mtime. 节点最新一次更新发生时的时间戳.
* dataVersion. 节点数据的更新次数.
* cversion. 其子节点的更新次数.
* aclVersion. 节点ACL(授权信息)的更新次数.
* ephemeralOwner. 如果该节点为ephemeral节点, ephemeralOwner值表示与该节点绑定的session id. 如果该节点不是ephemeral节点, ephemeralOwner值为0. 至于什么是ephemeral节点, 请看后面的讲述.
* dataLength. 节点数据的字节数.
* numChildren. 子节点个数.

## zxid

znode节点的状态信息中包含czxid和mzxid, 那么什么是zxid呢?
ZooKeeper状态的每一次改变, 都对应着一个递增的Transaction id, 该id称为zxid. 由于zxid的递增性质, 如果zxid1小于zxid2, 那么zxid1肯定先于zxid2发生. 创建任意节点, 或者更新任意节点的数据, 或者删除任意节点, 都会导致Zookeeper状态发生改变, 从而导致zxid的值增加.

## session

在client和server通信之前, 首先需要建立连接, 该连接称为session. 连接建立后, 如果发生连接超时, 授权失败, 或者显式关闭连接, 连接便处于CLOSED状态, 此时session结束.

## 创建不同类型的节点

节点的类型前面已经讲过。

创建一个临时节点

```
[zk: localhost:2181(CONNECTED) 12] create -e /hello world   
Created /hello
[zk: localhost:2181(CONNECTED) 13] get /hello
world
cZxid = 0x262ea78
ctime = Wed Mar 21 14:45:23 CST 2018
mZxid = 0x262ea78
mtime = Wed Mar 21 14:45:23 CST 2018
pZxid = 0x262ea78
cversion = 0
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x15c150a650f066c
dataLength = 5
numChildren = 0
```

创建一个序列节点

```
[zk: localhost:2181(CONNECTED) 14] create -s /hello1 world
Created /hello10000000007
[zk: localhost:2181(CONNECTED) 15] create -s /hello1 world
Created /hello10000000008
[zk: localhost:2181(CONNECTED) 16] ls /
[hello, dubbo, otter, zookeeper, seq, disconf, hello10000000007, hello10000000008, pinpoint-cluster]
[zk: localhost:2181(CONNECTED) 17] get /hello10000000007
world
cZxid = 0x262ea7e
ctime = Wed Mar 21 14:47:51 CST 2018
mZxid = 0x262ea7e
mtime = Wed Mar 21 14:47:51 CST 2018
pZxid = 0x262ea7e
cversion = 0
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 5
numChildren = 0
```
## watch

watch的意思是监听感兴趣的事件. 在命令行中, 以下几个命令可以指定是否监听相应的事件.

### ls命令

ls命令. ls命令的第一个参数指定znode, 第二个参数如果为true, 则说明监听该znode的子节点的增减, 以及该znode本身的删除事件.

```
[zk: localhost:2181(CONNECTED) 27] create /hello world
Created /hello
[zk: localhost:2181(CONNECTED) 28] ls /hello true
[]
[zk: localhost:2181(CONNECTED) 29] create /hello/test item001

WATCHER::

WatchedEvent state:SyncConnected type:NodeChildrenChanged path:/hello
Created /hello/test
```

### get命令

get命令. get命令的第一个参数指定znode, 第二个参数如果为true, 则说明监听该znode的更新和删除事件.

```
[zk: localhost:2181(CONNECTED) 30] get /hello true
world
cZxid = 0x262ef5d
ctime = Wed Mar 21 14:52:16 CST 2018
mZxid = 0x262ef5d
mtime = Wed Mar 21 14:52:16 CST 2018
pZxid = 0x262ef5e
cversion = 1
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 5
numChildren = 1
[zk: localhost:2181(CONNECTED) 31] create /hello/test1 item001
Created /hello/test1
[zk: localhost:2181(CONNECTED) 32] rmr /hello

WATCHER::

WatchedEvent state:SyncConnected type:NodeDeleted path:/hello
```

### stat命令

stat命令. stat命令用于获取znode的状态信息. 第一个参数指定znode, 如果第二个参数为true.

```
[zk: localhost:2181(CONNECTED) 35] create /hello world

WATCHER::

WatchedEvent state:SyncConnected type:NodeCreated path:/hello
Created /hello
[zk: localhost:2181(CONNECTED) 36] stat /hello true
cZxid = 0x262f0f0
ctime = Wed Mar 21 14:56:31 CST 2018
mZxid = 0x262f0f0
mtime = Wed Mar 21 14:56:31 CST 2018
pZxid = 0x262f0f0
cversion = 0
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 5
numChildren = 0
```



