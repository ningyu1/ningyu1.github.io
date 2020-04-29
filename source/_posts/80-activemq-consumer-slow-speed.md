---
toc : true
title : "ActiveMQ消息消费慢问题排查"
description : "ActiveMQ消息消费慢问题排查"
tags : [
	"activemq",
	"activemq slow speed"
]
date : "2018-05-09 15:38:00"
categories : [
    "trouble shooting"
]
menu : "main"
---

# 问题现象

有的时候会发现`ActiveMQ`中某个个队列的消息在写入后，不是立刻就被调度消费，而是需要等待一小会才能被调度消费（大概时间是1分钟），而且还伴随着这样的现象，当消息写入速度很快时消费很快，当消息写入消息速度很慢时反而消费很慢，我们的理解就是当写入慢的时候很多消费者都是闲置的那为什么消费反而会变慢？

# 问题原因

跟了一下代码发现了跟我们的设置有很大关系，因为我们设置的`receiveTimeout=6000`（1分钟）接受阻塞时间为1分钟。

`ActiveMQ`在消费时每个`consumer`会独占一个`Thread`，`Thead`中通过`consumer.receive()`去阻塞，只有当`consumer`消费了`maxMessagesPerTask`个消息后，才会退出线程，由`taskExecutor`重新调度，`maxMessagesPerTask`这个值默认为10，可以通过下面代码得知：

```
@Override
public void initialize() {
    // Adapt default cache level.
    if (this.cacheLevel == CACHE_AUTO) {
        this.cacheLevel = (getTransactionManager() != null ? CACHE_NONE : CACHE_CONSUMER);
    }
    // Prepare taskExecutor and maxMessagesPerTask.
    synchronized (this.lifecycleMonitor) {
        if (this.taskExecutor == null) {
            this.taskExecutor = createDefaultTaskExecutor();
        }
        else if (this.taskExecutor instanceof SchedulingTaskExecutor &&
                ((SchedulingTaskExecutor) this.taskExecutor).prefersShortLivedTasks() &&
                this.maxMessagesPerTask == Integer.MIN_VALUE) {
            // TaskExecutor indicated a preference for short-lived tasks. According to
            // setMaxMessagesPerTask javadoc, we'll use 10 message per task in this case
            // unless the user specified a custom value.
            this.maxMessagesPerTask = 10;
        }
    }
    // Proceed with actual listener initialization.
    super.initialize();
}
```

<span style="color:red">**ps. 我们使用的taskExecutor为：org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor，因此上面代码走到else if中设置this.maxMessagesPerTask = 10;**</span>

<span style="color:blue">**如果消息写入很快的时候，你会发现消费的很快，只有当消息写入很慢的时候（比如说：1分钟写入不到10条）的时候，才会发现消息消费的有些慢**</span>

# 解决方案

如果有这类情况，可以调整`receiveTime`这个参数，具体参数设置多少合理自己去结合业务场景去权衡，可以根据消息写入的速度和写入量来设置该参数（**`maxMessagesPerTask`** 和 **`receiveTimeout`**），调整这个参数有两种方式：

## 第一种使用JMS消费消息：

使用JMS消费消息时调整：`jmsTemplate`的`receiveTimeout`参数（以毫秒为单位，0表示阻塞接收不超时，默认值为0毫秒表示阻塞接受没有超时）

## 第二种使用listener-container消费消息：

使用`jms:listener-container`消费消息时调整：`receive-timeout`参数（以毫秒为单位， 默认值为1000毫秒（1秒）; -1指示器根本没有超时。）
