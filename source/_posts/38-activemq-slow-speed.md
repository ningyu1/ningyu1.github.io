---
toc : true
title : "ActiveMQ发送速度慢问题排查"
description : "ActiveMQ发送速度慢问题排查"
tags : [
	"activemq",
	"activemq slow speed"

]
date : "2017-11-09 17:00:36"
categories : [
    "trouble shooting"
]
menu : "main"
---

# 目录：
1. [关于使用发送消息给activemq的同步/异步发送问题需要注意](#sync-async-problem)
2. [同步/异步发送使用场景](#sync-async-scene)
3. [maxConnections配置问题注意事项](#maxconnections)
4. [idleTimeout配置问题注意事项](#idletimeout)
5. [关于Failover的问题](#failover)

## <a name="sync-async-problem">关于使用发送消息给activemq的同步/异步发送问题需要注意</a>

activemq发送异步参数：useAsyncSend与发送超时参数：sendTimeout是存在冲突的，
1. 当useAsyncSend=true，没有sendTimeout参数时（sendTimeout默认值0秒），走异步发送
2. 当useAsyncSend=false，没有sendTimeout参数时（sendTimeout默认值0秒），走同步发送
3. 当useAsyncSend=true，sendTimeout=1000，优先根据sendTimeout参数走同步发送

## <a name="sync-async-scene">同步/异步发送使用场景</a>

场景一：业务可以容忍消息丢失（日志记录）这样的场景使用：
使用：异步发送
配置：useAsyncSend=true，sendTimeout不配置（sendTimeout默认值0秒）
注意：可以不需要补偿机制
 
场景二：业务不能容忍消息丢失，这样的场景使用：
使用1：异步发送
配置1：useAsyncSend=true，sendTimeout不配置（sendTimeout默认值0秒）
注意1：当异步发送消息失败或异常导致消息丢失时有补偿的做法（如：定时任务、重发消息、等）
使用2：同步发送
配置2：useAsyncSend=false（useAsyncSend默认值false），sendTimeout=2000（超时时间一定要配置）
注意2：可以不需要补偿机制
 
场景三：业务必须将消息发送和jdbc事务放在一个事务内，保证数据的强一致性，这样的场景使用：
使用：同步发送
配置：useAsyncSend=false（useAsyncSend默认值false），sendTimeout=2000（超时时间一定要配置）
注意：消息发送的超时时间（sendTimeout）< jdbc事务超时时间
 
禁止使用的配置：
配置：useAsyncSend=false（useAsyncSend默认值false），sendTimeout不配置（sendTimeout默认值0秒）
注意：上面不配置超时时间的同步发送会造成请求阻塞在这里。

## <a name="maxconnections">maxConnections配置问题注意事项</a>

根据activemq的连接池实现代码，发现maxconnections不适合设置很大，除非并发非常高的情况下，因为现在activemq创建一个连接平均在1-2秒钟左右，根据activemq的连接实现发现

```
if (getConnectionsPool().getNumIdle(key) < getMaxConnections()) {
            try {
                connectionsPool.addObject(key);
                connection = mostRecentlyCreated.getAndSet(null);
                connection.incrementReferenceCount();
            } catch (Exception e) {
                throw createJmsException("Error while attempting to add new Connection to the pool", e);
            }
        } else {
            try {
                // We can race against other threads returning the connection when there is an
                // expiration or idle timeout.  We keep pulling out ConnectionPool instances until
                // we win and get a non-closed instance and then increment the reference count
                // under lock to prevent another thread from triggering an expiration check and
                // pulling the rug out from under us.
                while (connection == null) {
                    connection = connectionsPool.borrowObject(key);
                    synchronized (connection) {
                        if (connection.getConnection() != null) {
                            connection.incrementReferenceCount();
                            break;
                        }
                        // Return the bad one to the pool and let if get destroyed as normal.
                        connectionsPool.returnObject(key, connection);
                        connection = null;
                    }
                }
            } catch (Exception e) {
                throw createJmsException("Error while attempting to retrieve a connection from the pool", e);
            }
            try {
                connectionsPool.returnObject(key, connection);
            } catch (Exception e) {
                throw createJmsException("Error when returning connection to the pool", e);
            }
        }
```

当MaxConnections设置的很大的时候，会在发消息的时候一直判断池子中数量是否达到最大值，如果小于最大值再创建一个新的连接放入池子，这样就会前面发送消息的动作都会创建连接从而发送时间会增长。
比如：MaxConnections=20，发送消息50次，前20次都会去创建连接并且发送，后面30次会去复用连接池内的连接

## <a name="idletimeout">idleTimeout配置问题注意事项</a>

空闲时间配置问题，activemq默认idleTimeout=30秒，activemq开启failover的话它的连接创建时间相对较长，因此建议这个时间设置大一些，尽量不要让超时清空掉，提高复用率

## <a name="failover">关于Failover的问题</a>

activemq开启failover策略会根据配置的连接串中的tpc ip按顺序迭代去检测可用来创建连接，当可用的连接排在第一个的时候他的创建连接时间相比可用连接排在后面的时间短一些。
但是我们现在单个连接的时间耗时确实很高，这个问题不太清楚具体是什么问题，如下是创建连接耗时日志：
不开启failover的日志

```
耗时0：945ms
耗时1：1040ms
耗时2：595ms
耗时3：853ms
耗时4：716ms
耗时5：0ms
耗时6：0ms
耗时7：0ms
```

开启failover，可用连接排在第一位置，的日志

```
耗时0：2689ms
2017-11-03 18:47:20.599 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时1：1944ms
2017-11-03 18:47:22.615 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时2：1968ms
2017-11-03 18:47:24.724 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时3：2079ms
2017-11-03 18:47:25.318 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时4：608ms
耗时5：0ms
耗时6：0ms
耗时7：0ms
```

开启failover，可用连接排在最后的位置，的日志

```
耗时0：1960ms
2017-11-03 18:49:14.991 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时1：2084ms
2017-11-03 18:49:16.661 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时2：1775ms
2017-11-03 18:49:17.397 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时3：708ms
2017-11-03 18:49:18.066 [ActiveMQ Task-1] INFO  o.a.activemq.transport.failover.FailoverTransport - Successfully connected to tcp://10.51.232.238:61616
耗时4：864ms
耗时5：3ms
耗时6：0ms
耗时7：0ms
```

以上创建连接包括vpn加密的过程，可能会影响时间。
<span style="color:red">**ps.前五个是创建连接，因为我配置的5个连接数，后面都是连接复用，异步发送**</span>