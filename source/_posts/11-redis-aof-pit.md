---
toc : true
title : "Trouble Shooting —— Redis AOF rewrite错误导致Redis被Block住"
description : "Redis AOF踩过的坑"
tags : [
    "Redis",
    "AOF rewriting",
    "AOF",
    "Connnection reset by peer",
    "Numerical result out of range",
    "Cannot allocate memory",
    "Can't rewrite append only file in background",
	"调优"

]
date : "2017-08-15 10:30:34"
categories : [
    "Redis",
	"Case analysis",
	"trouble shooting"
]
menu : "main"
---


## 问题现状：

redis-cli 上去执行任何命令返回：connnection reset by peer

重启的应用无法连接到redis，已经建立连接的应用可以正常使用。

## 分析过程：

第一反应查看redis 日志，如下：

``` log
1838:M 16 Aug 01:07:39.319 # Error opening /setting AOF rewrite IPC pipes: Numerical result out of range
1838:M 16 Aug 01:07:39.319 * Starting automatic rewriting of AOF on 110% growth
1838:M 16 Aug 01:07:39.319 # Error opening /setting AOF rewrite IPC pipes: Numerical result out of range
1838:M 16 Aug 01:07:39.419 * Starting automatic rewriting of AOF on 110% growth
1838:M 16 Aug 01:07:39.419 # Error opening /setting AOF rewrite IPC pipes: Numerical result out of range
1838:M 16 Aug 01:07:39.441 # Error registering fd event for the new client: Numerical result out of range (fd=10311)
1838:M 16 Aug 01:07:39.457 # Error registering fd event for the new client: Numerical result out of range (fd=10311)
1838:M 16 Aug 01:07:39.457 # Error registering fd event for the new client: Numerical result out of range (fd=10311)
1838:M 16 Aug 01:07:39.461 # Error registering fd event for the new client: Numerical result out of range (fd=10311)
1838:M 16 Aug 01:07:39.461 # Error registering fd event for the new client: Numerical result out of range (fd=10311)
1838:M 16 Aug 01:07:39.462 # Error registering fd event for the new client: Numerical result out of range (fd=10311)
```

上面有两种错误日志

* Error opening /setting AOF rewrite IPC pipes: Numerical result out of range
	* 写aof出错了，超限
* Error registering fd event for the new client: Numerical result out of range (fd=10311)
	* 创建连接没有成功，能看到fd已经是10311 过万了

出现这种问题第一个先去看一下redis现在有多少个连接数

``` bash
>netstat -anp|grep 6379
>499
```

查看redis.conf中配置maxclients没有配置，redis默认为10000
这个时候有个疑问？为什么netstat查看的连接数只有499，但是redis日志中已经过万（ fd=10311）？这个问题值得思考？
我们通过查询进程的fd看一下具体打开了多少个连接（在linux中任何连接都是open file）

``` bash
>ls -al /proc/1838/fd | grep socket | wc -l
>499
 
>ls -al /proc/1838/fd | wc -l
>10322
```

为什么fd中socket的只有499，所有类型的确是10322呢？通过具体查看发现有9823个全都是pipe类型的连接

``` bash
>ls -al /proc/1838/fd | grep pipe | wc -l
>9823
```

为什么redis进程会有那么多pipe的连接呢？
难道是我们redis client使用的pipeline导致的连接泄漏？

于是查看了Jedis的源码

```
  /**
   * Synchronize pipeline by reading all responses. This operation close the pipeline. In order to
   * get return values from pipelined commands, capture the different Response&lt;?&gt; of the
   * commands you execute.
   */
  public void sync() {
    if (getPipelinedResponseLength() > 0) {
      List<Object> unformatted = client.getAll();
      for (Object o : unformatted) {
        generateResponse(o);
      }
    }
  }
```

能看到注释中有描述调用这个方法会操作连接关闭：This operation close the pipeline

又询问了开发的同学我们目前没有使用到pipelined，因此排除了这个可能

那问题来了是什么原因导致的pipe连接过多？

网上兜了一圈没发现有价值的信息，没办法只能去扫redis源码，

accetpCommonHandler函数源码：

```
static void acceptCommonHandler(int fd, int flags) {  
    redisClient *c;  
    if ((c = createClient(fd)) == NULL) {  
        redisLog(REDIS_WARNING,  
            "Error registering fd event for the new client: %s (fd=%d)",  
            strerror(errno),fd);  
        close(fd); /* May be already closed, just ignore errors */  
        return;  
    }  
    /* If maxclient directive is set and this is one client more... close the 
     * connection. Note that we create the client instead to check before 
     * for this condition, since now the socket is already set in non-blocking 
     * mode and we can send an error for free using the Kernel I/O */  
    if (listLength(server.clients) > server.maxclients) {  
        char *err = "-ERR max number of clients reached\r\n";  
   
        /* That's a best effort error message, don't check write errors */  
        if (write(c->fd,err,strlen(err)) == -1) {  
            /* Nothing to do, Just to avoid the warning... */  
        }  
        server.stat_rejected_conn++;  
        freeClient(c);  
        return;  
    }  
    server.stat_numconnections++;  
    c->flags |= flags;  
}
```

ps.这个函数主要调用createClient初始化客户端相关数据结构以及对应的socket，初始化后会判断当前连接的客户端是否超过最大值，如果超过的话，会拒绝这次连接。否则，更新客户端连接数的计数。
数据结构redisClient用于表示一个客户端的连接，包括一个客户多次请求的状态，createClient函数主要是初始化这个数据结构。在createClient函数中，首先是创建redisClient，然后是设置socket的属性，然后添加该socket的读事件

createClient函数源码：

```
if (fd != -1) {  
    anetNonBlock(NULL,fd);  
    // <MM>  
    // 关闭Nagle算法，提升响应速度  
    // </MM>  
    anetEnableTcpNoDelay(NULL,fd);  
    if (server.tcpkeepalive)  
        anetKeepAlive(NULL,fd,server.tcpkeepalive);  
    if (aeCreateFileEvent(server.el,fd,AE_READABLE,  
        readQueryFromClient, c) == AE_ERR)  
    {  
        close(fd);  
        zfree(c);  
        return NULL;  
    }  
}
```

ps.将socket设置为非阻塞的并且no delay，关闭Nagle算法，提升响应速度。最后会注册socket的读事件，事件处理函数是readQueryFromClient，这个函数便是客户端请求的起点，之后会详细介绍。

createClient函数的最后部分，就是对redisClient的属性初始化，代码不再列出。

当从acceptTcpHandler返回后，客户端的连接就建立完毕，接下来就是等待客户端的请求。

以上就是这个错误涉及到的redis源码

在redis的github上发现了有类似的问题issue：[https://github.com/antirez/redis/issues/2857](https://github.com/antirez/redis/issues/2857)

在源码aof.c文件中

```
/* Parent */    
server.stat_fork_time = ustime()-start;    
server.stat_fork_rate = (double) zmalloc_used_memory() * 1000000 / server.stat_fork_time / (1024*1024*1024); /* GB per second. */    
latencyAddSampleIfNeeded("fork",server.stat_fork_time/1000);    
if (childpid == -1) {    
serverLog(LL_WARNING,    
"Can't rewrite append only file in background: fork: %s",    
strerror(errno));      
return C_ERR;    
}
```

源码发现在报出Can't rewrite append only file in background: fork: %s这个错误的时候，没有关闭pipe连接

因此看到了redis官方的修复说明已经修复了这个问题，翻出github上的提交记录，如下

![redis1](/img/redis-pit/1.png)

这个时候看到了希望

于是搜索日志寻找是否有上图的错误：Can't rewrite append only file in background: fork

``` log
1838:M 15 Aug 13:52:01.101 # Can't rewrite append only file in background: fork: Cannot allocate memory
1838:M 15 Aug 13:52:01.202 * Starting automatic rewriting of AOF on 100% growth
1838:M 15 Aug 13:52:01.203 # Can't rewrite append only file in background: fork: Cannot allocate memory
1838:M 15 Aug 13:52:01.303 * Starting automatic rewriting of AOF on 100% growth
1838:M 15 Aug 13:52:01.304 # Can't rewrite append only file in background: fork: Cannot allocate memory
```

有很多我这里截取了前面的，总共出现的次数

``` bash
>less redis.log.1 | grep "Can't rewrite append only file in background: fork" | wc -l
>1644
```

基本可以断定是这个问题引发的连锁反应，这个时候我们需要研究一下Redis AOF机制，最终确认是否是这个问题导致。

研究redis AOF机制

redis aof rewirte机制，自动触发bgrewritedaof的条件：

```
long long growth =(server.appendonly_current_size*100/base) - 100;
if (growth >=server.auto_aofrewrite_perc)
```

我们的配置文件配置的auto-aof-rewrite-percentage 为100，也就是说当写入日志文件文件大小超过上次rewrite之后的文件大小的百分之100的时候就触发rewrite（也就是超过2倍）

ps.rewrite之后aof文件会保存keys的最后的状态，清除掉之前冗余的，来缩小这个文件。

## 通过分析aof rewrite发现rewrite出错就是导致Redis连接数超过最大值的罪魁祸首。

## 分析总结：
基本可以定位到，这个错误是个连锁反应最终导致Redis服务出现问题
* 首先redis在进行aof的rewrite的时候，会检查机器可以用的内存够不够支撑做aof rewrite，这个时候我们机器的可用内存太小，因此报了如下错误

```
Can't rewrite append only file in background: fork: Cannot allocate memory
```

* 但是rewirte自动触发机制当达到2倍的时候会一直触发，他就会一直尝试aof rewrite
* 在aof rewrite尝试的过程中，已经创建的连接还是可以正常使用，这导致aof的auto_aofrewrite_perc一直在增长但是无法写入到aof文件中，因此又暴漏出另外一个错误，如下所示

``` log
1838:M 16 Aug 01:07:39.319 * Starting automatic rewriting of AOF on 110% growth
1838:M 16 Aug 01:07:39.319 # Error opening /setting AOF rewrite IPC pipes: Numerical result out of range
```

* 当aof rewirte出错时，从redis代码也能看到，他没有调用close pipes管道连接，这个就造成了服务器上有大量连接被占用（pipe类型）

``` bash
>netstat -anp|grep 6379
>499

>ls -al /proc/1838/fd | grep socket | wc -l
>499

>ls -al /proc/1838/fd | grep pipe | wc -l
>9823

>ls -al /proc/1838/fd | wc -l
>10322
```

* 当连接到达maxclients 10000时就会拒绝新建连接，并且报如下错误

``` log
Error registering fd event for the new client: Numerical result out of range (fd=10311)
```

## 本次分析的结论
这个问题未解决需要继续跟踪，可能需要升级redis的版本，目前看到3.2.9以上才修复了这个bug，我们用的3.0.6版本的跨度有点大兼容性也需要考虑，还要对redis的配置在进一步研究，通过timeout配置让自动关闭无用的连接着也是一个解决问题的思路，这次只是先定位问题，具体解决还需要进一步研究

这个问题的issue：[#2857](https://github.com/antirez/redis/issues/2857)，[#2883](https://github.com/antirez/redis/issues/2883)

这个问题的提交记录：[fix #2883, #2857 pipe fds leak when fork() failed on bg aof rw](https://github.com/antirez/redis/commit/9b05aafb50348838f45bfddcd689e7d8d1d3c950)

问题修改的文件：[3.2.9分支 -> aof.c文件](https://github.com/antirez/redis/blob/3.2.9/src/aof.c)