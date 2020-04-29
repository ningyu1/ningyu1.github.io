---
toc : true
title : "Zookeeper事务日志和snapshot清理方式"
description : "Zookeeper事务日志和snapshot清理方式"
tags : [
	"zookeeper"
]
date : "2018-06-15 17:15:00"
categories : [
    "zookeeper"
]
menu : "main"
---

Zookeeper运行过程会产生大量的事务日志和snapshot镜像文件，文件的目录是通过`zoo.conf`的`datadir`参数指定的，下面我们就说一下如何清理事务日志和snapshot。

清理的方式有如下三种：


* [一、zookeeper配置自动清理](#zkConf)
* [二、使用自定义清理脚本](#shell)
* [三、使用zkCleanup.sh清理](#zkCleanup)

下面我们一一介绍每种清理方式是如何使用的。

# <span id = "zkConf">zookeeper配置自动清理</span>

zookeeper在3.4.0版本以后提供了自动清理snapshot和事务日志的功能通过配置 autopurge.snapRetainCount 和 autopurge.purgeInterval 这两个参数能够实现定时清理了。这两个参数都是在zoo.cfg中配置的：

我们使用的zk版本是：3.4.6，因此可以使用自带的清理功能

autopurge.purgeInterval  这个参数指定了清理频率，单位是小时，需要填写一个1或更大的整数，默认是0，表示不开启自己清理功能。

autopurge.snapRetainCount 这个参数和上面的参数搭配使用，这个参数指定了需要保留的文件数目。默认是保留3个。

示例：

```
autopurge.snapRetainCount=60 
autopurge.purgeInterval=48
```

保留48小时内的日志，并且保留60个文件

<span style="color:red">*ps.但是修改conf需要重启服务，生产可能不会考虑重启服务因此使用其他方法。*</span>

# <span id = "shell">使用自定义清理脚本</span>

clean_zook_log.sh脚本内容如下

```
#!/bin/bash
            
#snapshot file dir
dataDir=/var/zookeeper/version-2
#tran log dir
dataLogDir=/var/zookeeper/version-2
logDir=/usr/local/zookeeper/logs
#Leave 60 files
count=60
count=$[$count+1]
ls -t $dataLogDir/log.* | tail -n +$count | xargs rm -f
ls -t $dataDir/snapshot.* | tail -n +$count | xargs rm -f
ls -t $logDir/zookeeper.log.* | tail -n +$count | xargs rm -f
```

这个脚本保留最新的60个文件，可以将他写到 将这个脚本添加到crontab中，设置为每天凌晨2点？或者其他时间执行即可。

```
crontab -e 2 2 * * * /bin/bash /usr/local/zookeeper/bin/clean_zook_log.sh > /dev/null 2>&1
```

<span style="color:red">*ps.不用修改配置，不需要重启zk集群，推荐使用*</span>

# <span id = "zkCleanup">使用zkCleanup.sh清理</span>

这个脚本是使用的zookeeper.jar里的`org.apache.zookeeper.server.PurgeTxnLog`这个class的main函数清理的，因此需要启动一个java进程，比shell清理要重一些。

[`org.apache.zookeeper.server.PurgeTxnLog`文档](http://zookeeper.apache.org/doc/r3.4.3/api/index.html)

```
sh /usr/local/zookeeper/bin/zkCleanup.sh 数据目录 -n 20
```

参数说明

数据目录： /var/zookeeper
20:  保留快照日志的数量

<span style="color:red">*ps.因为zookeeper从3.4.0版本之后提供了对历史事务日志和快照文件的自动清理，所以这个脚本很少使用，另外在生产环境中我们一般采取自动脚本来定点定量清除指定日期的日志文件*</span>

到这里三种清理方式都介绍完毕了，根据自己的实际情况选择一种使用就可以了。祝大家周末愉快以及端午节快乐，ok 收工 回家。