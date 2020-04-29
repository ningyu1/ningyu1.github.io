---
toc : true
title : "ActiveMQ使用经验分享，配置详解"
description : "ActiveMQ使用经验分享，配置详解"
tags : [
    "MQ",
	"ActiveMQ"
]
date : "2017-05-11 12:03:10"
categories : [
    "ActiveMQ"
]
menu : "main"
---

根据我们的使用场景抽取出来了一系列activemq公共配置参数mq.properties

## mq.properties
```
activemq.connnect.brokerurl=failover:(tcp://192.168.0.66:61616)
activemq.connnect.useAsyncSend=true
# object对象接受报名单,true不受限制,false需要设置白名单
activemq.connnect.trustAllPackages=true
 
# 最大连接数
activemq.pool.maxConnections=20
# 空闲失效时间,毫秒
activemq.pool.idleTimeout=60000
 
# 初始数量
activemq.listener.pool.corePoolSize=5
activemq.listener.pool.maxPoolSize=10
# 启动守护进程
activemq.listener.pool.daemon=true
# 单位秒
activemq.listener.pool.keepAliveSeconds=120

# 由于jms:listener-container不支持propertyPlaceholder替换，因此这些参数值写在spring-mq.xml文件中，参考值
# 
# 接收消息时的超时时间,单位毫秒
activemq.consumer.receiveTimeout=60000
# 监听目标类型
activemq.listener.destinationtype=queue
# 监听确认消息方式
activemq.listener.acknowledge=auto
# 监听数量
activemq.listener.concurrency=2-10
```

## spring-mq.xml
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:context="http://www.springframework.org/schema/context"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:amq="http://activemq.apache.org/schema/core"
    xmlns:jms="http://www.springframework.org/schema/jms"
    xsi:schemaLocation="http://www.springframework.org/schema/beans   
        http://www.springframework.org/schema/beans/spring-beans-4.0.xsd   
        http://www.springframework.org/schema/context   
        http://www.springframework.org/schema/context/spring-context-4.0.xsd
        http://www.springframework.org/schema/jms
        http://www.springframework.org/schema/jms/spring-jms-4.0.xsd
        http://activemq.apache.org/schema/core
        http://activemq.apache.org/schema/core/activemq-core-5.8.0.xsd">
 
    <!-- 配置activeMQ连接 tcp://192.168.0.66:61616 -->
    <bean id="targetConnectionFactory" class="org.apache.activemq.ActiveMQConnectionFactory">
        <property name="brokerURL" value="${activemq.connnect.brokerurl}" />
        <!-- useAsyncSend 异步发送 -->
        <property name="useAsyncSend" value="${activemq.connnect.useAsyncSend}"></property>
        <!-- 关闭对象传输有白名单限制 -->
        <property name="trustAllPackages" value="${activemq.connnect.trustAllPackages}"></property>
    </bean>
 
    <!-- 通过往PooledConnectionFactory注入一个ActiveMQConnectionFactory可以用来将Connection，Session和MessageProducer池化 
        这样可以大大减少我们的资源消耗， -->
    <bean id="pooledConnectionFactory" class="org.apache.activemq.pool.PooledConnectionFactory">
        <property name="connectionFactory" ref="targetConnectionFactory" />
        <property name="maxConnections" value="${activemq.pool.maxConnections}" />
        <property name="idleTimeout" value="${activemq.pool.idleTimeout}" />
        <!-- maximumActiveSessionPerConnection : 500  每个连接中使用的最大活动会话数 -->
        <!-- idleTimeout : 30 * 1000 单位毫秒 -->
        <!-- blockIfSessionPoolIsFull : true -->
        <!-- blockIfSessionPoolIsFullTimeout : -1L -->
        <!-- expiryTimeout : 0L -->
        <!-- createConnectionOnStartup : true -->
        <!-- useAnonymousProducers : true -->
        <!-- reconnectOnException : true -->
        <!-- maxConnections : 默认1 -->
        <!-- timeBetweenExpirationCheckMillis : -1 -->
    </bean>
 
    <!-- 线程池配置 -->
    <bean id="queueMessagee x e cutor"
        class="org.springframework.scheduling.concurrent.ThreadPoolTaske x e cutor">
        <property name="corePoolSize" value="${activemq.listener.pool.corePoolSize}" />
        <property name="maxPoolSize" value="${activemq.listener.pool.maxPoolSize}" />
        <property name="daemon" value="${activemq.listener.pool.daemon}" />
        <property name="keepAliveSeconds" value="${activemq.listener.pool.keepAliveSeconds}" />
    </bean>
 
    <!-- 定义JmsTemplate的Queue类型 -->
    <bean id="jmsTemplate" class="org.springframework.jms.core.JmsTemplate">
        <constructor-arg ref="pooledConnectionFactory" />
        <!-- deliveryMode : PERSISTENT 默认保存消息 -->
        <!-- messageIdEnabled : true 默认有消息id -->
        <!-- messageTimestampEnabled : true 默认有消息发送时间 -->
        <!-- pubSubNoLocal : false,默认点对点(Queues) -->
        <!-- receiveTimeout : 0 阻塞接收不超时,接收消息时的超时时间,单位毫秒  -->
        <!-- deliveryDelay : 0  -->
        <!-- explicitQosEnabled : false  -->
        <!-- priority : 4  -->
        <!-- timeToLive : 0  -->
        <!-- pubSubDomain : false  -->
        <!-- defaultDestination : 默认目标，默认null  -->
        <!-- messageConverter : 消息转换器，默认SimpleMessageConverter  -->
        <!-- sessionTransacted : 事务控制，默认false  -->
    </bean>
 
    <!-- 定义Queue监听器 -->
    <!-- 由于jms:listener-container不支持propertyPlaceholder替换，因此这些参数值写在spring-mq.xml文件中，参考值：mq.properties文件中 -->
    <jms:listener-container task-e x e cutor="queueMessagee x e cutor" receive-timeout="60000"
        destination-type="queue" container-type="default" connection-factory="pooledConnectionFactory"
        acknowledge="auto" concurrency="2-10" >
        <jms:listener destination="QUEUE.EMAIL" ref="mailMessageListener" />
        <jms:listener destination="QUEUE.SMS" ref="smsMessageListener" />
    </jms:listener-container>
 
    <bean id="smsMessageListener"
        class="org.springframework.jms.listener.adapter.MessageListenerAdapter">
        <!-- 默认调用方法handleMessage -->
        <property name="delegate">
            <bean class="com.domain.framework.message.sms.listener.SMSMessageListener" />
        </property>
        <property name="defaultListenerMethod" value="receiveMessage"/>
    </bean>
     
    <bean id="mailMessageListener"
        class="org.springframework.jms.listener.adapter.MessageListenerAdapter">
        <!-- 默认调用方法handleMessage -->
        <property name="delegate">
            <bean class="com.domain.framework.message.mail.listener.EmailMessageListener" />
        </property>
        <property name="defaultListenerMethod" value="receiveMessage"/>
    </bean>
 
</beans>
```

## 配置说明
1. trustAllPackages
	1. 等于false时，在做object序列化时会有Class Not Found Exception：This class is not trusted to be serialized as ObjectMessage payload异常抛出，是因为activemq服务器默认是不接受object序列化对象，需要配置白名单（接受的object对象class全名）
	2. 等于true时关闭验证
	3. 传输对象安全说明: [http://activemq.apache.org/objectmessage.htm](http://activemq.apache.org/objectmessage.htm "http://activemq.apache.org/objectmessage.htm")
2. useAsyncSend
	1. 开启异步消息发送，主要是一个性能上的提升从而提升消息吞吐量，但是不能拿到消息发送后的回执消息，消息不会丢失
	2. 异步发送的说明：[http://activemq.apache.org/async-sends.html](http://activemq.apache.org/async-sends.html "http://activemq.apache.org/async-sends.html")
3. executor corePoolSize
	1. 该值的配置需要结合listener的个数和concurrency的数量去灵活配置
	
	案例分析

	```
	<bean id="queueMessageExecutor"
	    class="org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor">
	    <property name="corePoolSize" value="2" />
	    <property name="maxPoolSize" value="10" />
	    <property name="daemon" value="true" />
	    <property name="keepAliveSeconds" value="120" />
	</bean>
	<jms:listener-container task-executor="queueMessageExecutor" receive-timeout="60000"
	    destination-type="queue" container-type="default" connection-factory="pooledConnectionFactory"
	    acknowledge="auto" concurrency="2-10" >
	    <jms:listener destination="QUEUE.EMAIL" ref="mailMessageListener" />
	    <jms:listener destination="QUEUE.SMS" ref="smsMessageListener" />
	</jms:listener-container>
	```
	项目中有2个listener并且项目希望启动初始每个listener启动2个consumer最大10个consumer，如果e x e cutor corePoolSize配置为2，那么启动后只会给一个listener分配2个consumer，因为e x e cutor pool的初始配置数量不够，见下图

	![activemq1](/img/activemq/1.jpg)
	修改corePoolSize之后
	```
	<property name="corePoolSize" value="5" />
	```
	![activemq2](/img/activemq/2.jpg)
4. executor daemon
	1. 是否创建守护线程
	2. 设置为true时，在应用程序在紧急关闭时，任然会执行没有完成的runtime线程 
5. jms:listener-container
	1. 由于不支持propertyPlaceholder替换，因此这些参数值写在spring-mq.xml文件中，参考值：mq.properties文件中
	2. destination-type 目标类型（QUEUE, TOPIC, DURABLETOPIC）
	3. acknowledge 消息确认方式（auto、client、dups-ok、transacted）
	4. concurrency listener consumer个数
6. message-converter 
	1. 消息转换器，我们这里不配置特殊的转换器，使用Spring提供的org.springframework.jms.support.converter.SimpleMessageConverter.SimpleMessageConverter()简单转换器，支持对象（String、byte[]、Map、Serializable）
	2. 结合org.springframework.jms.listener.adapter.MessageListenerAdapter做接受消息自动转换对象
	3. 结合org.springframework.jms.core.JmsTemplate使用convertAndSend系列方法对象转换并发送，实现发送消息自动转换。
	4. 我们为什么不使用json做消息转换，因为json转换在反序列话时需要明确序列化Class类型，丢失了消息转换器的通用性。
7. Listener
	1. 支持实现JMS接口的类javax.jms.MessageListener，它是一个来自JMS规范的标准化接口，但是你要处理线程。。
	2. 支持Spring SessionAwareMessageListener，这是一个Spring特定的接口，提供对JMS会话对象的访问。 这对于请求 - 响应消息传递非常有用。 只需要注意，你必须做自己的异常处理（即，重写handleListenerException方法，这样异常不会丢失）。
	3. 支持Spring MessageListenerAdapter，这是一个Spring特定接口，允许特定类型的消息处理。 使用此接口可避免代码中任何特定于JMS的依赖关系。
8. MessageListenerAdapter
	1. 可以代理任意POJO类，无需实现JMS接口，任意指定回调方法，并且消息转换内置实现，JMS会话默认封装
	使用示例：
	消息接收
	
	```
	<bean id="mailMessageListener"
	    class="org.springframework.jms.listener.adapter.MessageListenerAdapter">
	    <!-- 默认调用方法handleMessage -->
	    <property name="delegate">
	        <bean class="com.domain.framework.message.mail.listener.EmailMessageListener" />
	    </property>
	    <property name="defaultListenerMethod" value="receiveMessage"/>
	</bean>
	
	public class EmailMessageListener {
	    public void receiveMessage(EmailMessageVo message) {
	        ...someing....
	    }
	}
	```
	消息发送
	```
	<bean id="jmsTemplate" class="org.springframework.jms.core.JmsTemplate">
	    <constructor-arg ref="pooledConnectionFactory" />
	</bean>
	
	@Component("emailService")
	public class EmailServiceImpl implements IEmailService {
	    @Autowired
	    private JmsTemplate jmsTemplate;
	     
	    @Override
	    public void sendEmailMessage(EmailMessageVo message) throws BizException {
	        if(message != null) {
	            jmsTemplate.convertAndSend(QueueNames.EMAIL, message);
	        } else {
	            logger.warn("sendEmailMessage() param[message] is null ,can't send message!");
	        }
	    }
	}
	```

	**ps.上面的示例主要是org.springframework.jms.core.JmsTemplate与org.springframework.jms.listener.adapter.MessageListenerAdapter和业务的POJO做消费者的一个结合使用示例，无需关注序列化，发送与接受对象直接使用业务POJO**
9. Q名称的命名规则
	1. 名称我们采用大写字母，多个单词之间分隔符使用“.”,例如：QUEUE.XXX、TOPIC.XXX
	2. 根据产品线或项目名称增加namespace，例如：APP1.QUEUE.XXX、APP2.QUEUE.XXX
10. Active MQ包使用说明
	1. 不要使用activemq-all这个包，这个包打包了依赖（pool源码，spring源码，log4j源码，jms源码），会跟我们的日志框架产生冲突
	2. 我们使用activemq-pool、activemq-client、activemq-broker、spring-jms去替换上面的activemq-all包

	![activemq3](/img/activemq/3.jpg)

**Spring+Activemq使用配置非常灵活，我们不拘泥于一种形式，如果有更好的经验尽管提出来我们共同努力和进步。**


