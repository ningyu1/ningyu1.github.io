---
toc : true
title : "Trouble Shooting —— jms:listener-container配置queue的concurrency数量与预期不一致"
description : "Trouble Shooting —— jms:listener-container配置queue的concurrency数量与预期不一致"
tags : [
	"activemq"
]
date : "2018-10-30 18:40:00"
categories : [
    "activemq",
	"trouble shooting"
]
menu : "main"
---

* [问题描述](#103-desc)
	* [现象一](#103-1)
	* [现象二](#103-2)
* [测试消费者](#103-test)
* [测试后结论](#103-solution)

# <span id = "103-desc">问题描述</span>

测试程序时发现queue的consumer数量配置与预期不一致，具体如何不一致看下面的测试。

## <span id = "103-1">现象一</span>

当我们使用下面配置，listener使用同一个task-executor并且监听三个queue时，consumer使用20-20，只会有一个queue能达到20个consumer，其余两个queue的consumer=0

```
<bean id="queueMessageExecutor1" class="org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor">
   <property name="corePoolSize" value="20" />
   <property name="maxPoolSize" value="20" />
   <property name="daemon" value="true" />
   <property name="keepAliveSeconds" value="120" />
</bean>
<jms:listener-container task-executor="queueMessageExecutor1" destination-type="queue" container-type="default" connection-factory="pooledConnectionFactory"
                  concurrency="20-20" acknowledge="auto" receive-timeout="60000">
   <jms:listener destination="QUEUE.EMAIL" ref="mailMessageListener" />
   <jms:listener destination="QUEUE.SMS" ref="smsMessageListener" />
   <jms:listener destination="QUEUE.WECHAT" ref="wechatMessageListener" />
</jms:listener-container>
```

效果如下图：

![](/img/activemq-listener-concurrency/1.png)

## <span id = "103-2">现象二</span>

当我们去掉listener-container的`receive-timeout="60000"`的配置，三个queue的consumer都等于20。

```
<bean id="queueMessageExecutor1" class="org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor">
   <property name="corePoolSize" value="20" />
   <property name="maxPoolSize" value="20" />
   <property name="daemon" value="true" />
   <property name="keepAliveSeconds" value="120" />
</bean>
<jms:listener-container task-executor="queueMessageExecutor1" destination-type="queue" container-type="default" connection-factory="pooledConnectionFactory"
                  concurrency="20-20" acknowledge="auto">
   <jms:listener destination="QUEUE.EMAIL" ref="mailMessageListener" />
   <jms:listener destination="QUEUE.SMS" ref="smsMessageListener" />
   <jms:listener destination="QUEUE.WECHAT" ref="wechatMessageListener" />
</jms:listener-container>
```

效果如下图：

![](/img/activemq-listener-concurrency/2.png)

这两种现象之间的差异就在`receive-timeout="60000"`这个属性上，接下来让我们看一下“现象一”、“现象二”的jvm启动的consumer线程的具体信息，如下图：

现象一的线程信息：

![](/img/activemq-listener-concurrency/3.png)

现象二的线程信息：

![](/img/activemq-listener-concurrency/4.png)

从线程的信息上看，线程的数量与线程池的配置信息吻合，具体开多少个线程取决于线程池的大小，这个与预期一致，拿为什么两种现象锁显示的queue的consumer数量不同呢？

同样是20个线程，但是在现象二中三个queue的consumer分别都是20个，那总数就是60个完全超过了线程的数量，从这点能看的出来consumer的数量是逻辑数量，也就是说20个线程来承接60个逻辑消费者，每个线程会随机的去拿某一个queue里的消息。

# <span id = "103-test">测试消费者</span>

当我们在“现象一”中只有一个queue有consumer，其他queue没有consumer，我们往没有consumer的q中写消息，看些消息的这个q是否有会consumer出现？

![](/img/activemq-listener-concurrency/5.png)

当消息积压到一定的时间（测试下来时间为：14:18分积压消息，14:27分增加了20个consumer消费掉了积压消息）

![](/img/activemq-listener-concurrency/6.png)

我们再往wechat中发送积压消息，看看wechat的consumer是否会增加？

![](/img/activemq-listener-concurrency/7.png)

当消息积压到一定的时间（测试下来时间为：14:34分积压消息，14:38分增加了20个consumer消费掉了积压消息）

![](/img/activemq-listener-concurrency/8.png)

一旦增加上来了consumer目前看下来不会自动消失

# <span id = "103-solution">测试后结论</span>

当listener-container使用同一个`task-executor`并且监听多个q时：

* listener-container设置了`receive-timeout="60000`（接受超时时间），线程数会优先处理配置中第一个q上，其他q不会有consumer数量，当其他q有消息积压时会自动增加consumer数量，但是增加的时间不太规律。
* listener-container没有设置`receive-timeout="60000`（接受超时时间），线程数会处理多个q的消息接收，随机接收某个q的消息，或者是那个q的消息积压的多会优先接受那个q的消息。

ps. 同一个listener-container监听多个q，线程会接收多个q的消息（多个q共享接收消息线程），只不过q的consumer数量初始化的时间不同，如果不配置`receive-timeout="60000`（接受超时时间）这个参数，q的consumer数量在启动时就会初始化。

当listener-container使用不同的`task-executor`并且只监听一个q时：

* 设不设置`receive-timeout="60000`（接受超时时间）没有区别，一个线程池中的线程只会处理一个q的消息接收，对于消息量大存在积压的情况下，可以独立配置线程池和监听器让这个q的处理线程资源独享。


