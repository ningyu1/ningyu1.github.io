---
toc : true
title : "Trouble Shooting —— MyBatis的PropertyTokenizer抛NPE异常"
description : "Trouble Shooting —— MyBatis的PropertyTokenizer抛NPE异常"
tags : [
	"mybatis"
]
date : "2018-08-20 17:48:00"
categories : [
    "mybatis",
	"trouble shooting"
]
menu : "main"
---

这个文章转自公司内网WIKI，同事调试的问题以及问题分析过程，我觉得挺好的所以转载出来。

# 问题描述

多任务同时处理时会报出如下NPE异常，堆栈信息如下：

```
2018-08-10 18:16:10.938 [xxxExecutor-2] ERROR c.j.bmc.mq.listener.xxxResultListener 
org.mybatis.spring.MyBatisSystemException: nested exception is org.apache.ibatis.exceptions.PersistenceException:
### Error querying database.  Cause: java.lang.NullPointerException
### Cause: java.lang.NullPointerException
    at org.mybatis.spring.MyBatisExceptionTranslator.translateExceptionIfPossible(MyBatisExceptionTranslator.java:75) ~[mybatis-spring-1.2.2.jar:1.2.2]
    at org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:371) ~[mybatis-spring-1.2.2.jar:1.2.2]
    at com.sun.proxy.$Proxy21.selectList(Unknown Source) ~[na:na]
    at org.mybatis.spring.SqlSessionTemplate.selectList(SqlSessionTemplate.java:198) ~[mybatis-spring-1.2.2.jar:1.2.2]
    at org.apache.ibatis.binding.MapperMethod.executeForMany(MapperMethod.java:119) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.binding.MapperMethod.execute(MapperMethod.java:63) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.binding.MapperProxy.invoke(MapperProxy.java:52) ~[mybatis-3.2.7.jar:3.2.7]
    at com.sun.proxy.$Proxy49.findBillBillingTask(Unknown Source) ~[na:na]
    at com.xxx.service.impl.XXXServiceImpl.findBillBillingTask(XXXServiceImpl.java:118) ~[bmc-service-0.0.1-SNAPSHOT.jar:na]
    at com.xxx.service.impl.XXXServiceImpl$$FastClassByCGLIB$$7d4463f0.invoke(<generated>) ~[spring-core-4.0.0.RELEASE.jar:na]
    at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204) ~[spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.invokeJoinpoint(CglibAopProxy.java:713) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:157) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.transaction.interceptor.TransactionInterceptor$1.proceedWithInvocation(TransactionInterceptor.java:98) ~[spring-tx-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:262) ~[spring-tx-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:95) ~[spring-tx-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:646) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at com.xxx.service.impl.XXXServiceImpl$$EnhancerByCGLIB$$32d6287d.findBillBillingTask(<generated>) ~[spring-core-4.0.0.RELEASE.jar:na]
    at com.xxx.service.impl.XXXResultServiceImpl.saveBillBillingTask(XXXResultServiceImpl.java:213) ~[bmc-service-0.0.1-SNAPSHOT.jar:na]
    at com.xxx.service.impl.XXXResultServiceImpl.disposeBillBillingResult(XXXResultServiceImpl.java:193) ~[bmc-service-0.0.1-SNAPSHOT.jar:na]
    at com.xxx.service.impl.XXXResultServiceImpl$$FastClassByCGLIB$$5e8db258.invoke(<generated>) ~[spring-core-4.0.0.RELEASE.jar:na]
    at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204) ~[spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.invokeJoinpoint(CglibAopProxy.java:713) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:157) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.transaction.interceptor.TransactionInterceptor$1.proceedWithInvocation(TransactionInterceptor.java:98) ~[spring-tx-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:262) ~[spring-tx-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:95) ~[spring-tx-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:646) ~[spring-aop-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at com.xxx.service.impl.XXXResultServiceImpl$$EnhancerByCGLIB$$8d251e5.disposeBillBillingResult(<generated>) ~[spring-core-4.0.0.RELEASE.jar:na]
    at com.xxx.XXXListener.receiveMessage(BillBillingResultListener.java:92) ~[bmc-main-0.0.1-SNAPSHOT.jar:na]
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[na:1.7.0_79]
    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57) ~[na:1.7.0_79]
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.7.0_79]
    at java.lang.reflect.Method.invoke(Method.java:606) ~[na:1.7.0_79]
    at org.springframework.util.MethodInvoker.invoke(MethodInvoker.java:273) [spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.adapter.MessageListenerAdapter.invokeListenerMethod(MessageListenerAdapter.java:466) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.adapter.MessageListenerAdapter.onMessage(MessageListenerAdapter.java:357) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.adapter.MessageListenerAdapter.onMessage(MessageListenerAdapter.java:332) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.AbstractMessageListenerContainer.doInvokeListener(AbstractMessageListenerContainer.java:537) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.AbstractMessageListenerContainer.invokeListener(AbstractMessageListenerContainer.java:497) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.AbstractMessageListenerContainer.doExecuteListener(AbstractMessageListenerContainer.java:468) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.AbstractPollingMessageListenerContainer.doReceiveAndExecute(AbstractPollingMessageListenerContainer.java:325) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.AbstractPollingMessageListenerContainer.receiveAndExecute(AbstractPollingMessageListenerContainer.java:263) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.DefaultMessageListenerContainer$AsyncMessageListenerInvoker.invokeListener(DefaultMessageListenerContainer.java:1104) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at org.springframework.jms.listener.DefaultMessageListenerContainer$AsyncMessageListenerInvoker.run(DefaultMessageListenerContainer.java:998) [spring-jms-4.0.0.RELEASE.jar:4.0.0.RELEASE]
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145) [na:1.7.0_79]
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615) [na:1.7.0_79]
    at java.lang.Thread.run(Thread.java:745) [na:1.7.0_79]
Caused by: org.apache.ibatis.exceptions.PersistenceException:
### Error querying database.  Cause: java.lang.NullPointerException
### Cause: java.lang.NullPointerException
    at org.apache.ibatis.exceptions.ExceptionFactory.wrapException(ExceptionFactory.java:26) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:111) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:102) ~[mybatis-3.2.7.jar:3.2.7]
    at sun.reflect.GeneratedMethodAccessor203.invoke(Unknown Source) ~[na:na]
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.7.0_79]
    at java.lang.reflect.Method.invoke(Method.java:606) ~[na:1.7.0_79]
    at org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:358) ~[mybatis-spring-1.2.2.jar:1.2.2]
    ... 48 common frames omitted
Caused by: java.lang.NullPointerException: null
    at org.apache.ibatis.reflection.property.PropertyTokenizer.<init>(PropertyTokenizer.java:30) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.reflection.MetaObject.getValue(MetaObject.java:107) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.DynamicContext$ContextMap.get(DynamicContext.java:97) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.DynamicContext$ContextAccessor.getProperty(DynamicContext.java:116) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.OgnlRuntime.getProperty(OgnlRuntime.java:1657) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.ASTProperty.getValueBody(ASTProperty.java:92) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.SimpleNode.evaluateGetValueBody(SimpleNode.java:170) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.SimpleNode.getValue(SimpleNode.java:210) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.ASTNotEq.getValueBody(ASTNotEq.java:49) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.SimpleNode.evaluateGetValueBody(SimpleNode.java:170) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.SimpleNode.getValue(SimpleNode.java:210) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.Ognl.getValue(Ognl.java:333) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.Ognl.getValue(Ognl.java:413) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.ognl.Ognl.getValue(Ognl.java:395) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.OgnlCache.getValue(OgnlCache.java:48) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.ExpressionEvaluator.evaluateBoolean(ExpressionEvaluator.java:32) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.IfSqlNode.apply(IfSqlNode.java:33) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.MixedSqlNode.apply(MixedSqlNode.java:32) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.scripting.xmltags.DynamicSqlSource.getBoundSql(DynamicSqlSource.java:40) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.mapping.MappedStatement.getBoundSql(MappedStatement.java:278) ~[mybatis-3.2.7.jar:3.2.7]
    at org.apache.ibatis.executor.CachingExecutor.query(CachingExecutor.java:75) ~[mybatis-3.2.7.jar:3.2.7]
    at sun.reflect.GeneratedMethodAccessor205.invoke(Unknown Source) ~[na:na]
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:1.7.0_79]
    at java.lang.reflect.Method.invoke(Method.java:606) ~[na:1.7.0_79]
    at org.apache.ibatis.plugin.Invocation.proceed(Invocation.java:49) ~[mybatis-3.2.7.jar:3.2.7]
    at com.github.pagehelper.util.SqlUtil.doIntercept(SqlUtil.java:175) ~[pagehelper-4.2.1.jar:na]
    at com.github.pagehelper.util.SqlUtil.intercept(SqlUtil.java:84) ~[pagehelper-4.2.1.jar:na]
    at com.github.pagehelper.PageHelper.intercept(PageHelper.java:50) ~[pagehelper-4.2.1.jar:na]
    at org.apache.ibatis.plugin.Plugin.invoke(Plugin.java:60) ~[mybatis-3.2.7.jar:3.2.7]
    at com.sun.proxy.$Proxy53.query(Unknown Source) ~[na:na]
    at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:108) ~[mybatis-3.2.7.jar:3.2.7]
    ... 53 common frames omitted
```

# 分析过程

通常，有堆栈数据的时候就很容分析出问题的原因。但是经过查看相关代码后发现触发点操作逻辑非常简单，不太会出现该异常。

于是就考虑从日志的细节分析问题。

先查看业务代码。该代码使用一个非空的VO对象作为查询条件，提交给Mapper。

Mapper中，判断各个参数是否为null或者空，然后拼接到SQL中。整个过程非常简单，而且大部分是成功执行的。

通过以上判断，可以认为不是业务代码的问题，极有可能是mybatis的问题。于是上网进行搜索，得到一些关于偶发NPE问题的描述。

[mybatis-3/issues/313](https://github.com/mybatis/mybatis-3/issues/313)

[mybatis-3/issues/199](https://github.com/mybatis/mybatis-3/issues/199)

以下问题提及了偶发返回null的情况。

[issues-OGNL-121](https://issues.apache.org/jira/browse/OGNL-121)

![](/img/mybatis-npe/1.png)

于是我们又观察反编译代码和日志执行情况，可以看到在SimpleNode.java中的确有非安全的逻辑操作。

![](/img/mybatis-npe/2.png)

![](/img/mybatis-npe/3.png)

日志也有相关的执行过程。

![](/img/mybatis-npe/4.png)

由于没有源代码，所以无法有效的进行Debug，模拟并发操作。因此该问题只能怀疑是这个原因导致的，具体可以在后续

有条件的情况下进行模拟测试。

# 深入并发测试

在Idea中可以反编译代码，且还原度较高，因此我们做了一次测试。

## 测试环境

两个Consumer调用Provider，Provider只做数据库查询，且查询中带条件判断。

这里使用Spring test进行测试，以下是Consumer端调用

![](/img/mybatis-npe/5.png)

Provider端定义

![](/img/mybatis-npe/6.png)

查询条件判断

![](/img/mybatis-npe/7.png)

准备好测试环境后，就可以进行测试了。此处还需要注意如何在IntellJ Idea中Debug多线程，具体设置方法请找度娘。

## 测试过程

同时启动两个Consumer，然后在Provider中的SimpleNode.java中设置断点。

根据之前分析，如果要出现null，则说明getProperty会返回null。

![](/img/mybatis-npe/8.png)

而getValue方法实际调用的逻辑是以下代码：

![](/img/mybatis-npe/9.png)

说明以下的代码返回了null

![](/img/mybatis-npe/10.png)

从代码上及Debug分析，如果要返回null，则很有可能在hasConstantValue=true且constantValue为null。

当然此处的数据已经是我们模拟出并发问题后的结果，也验证了是有可能的。

![](/img/mybatis-npe/11.png)

如果没有出问题的情况时，正常的结果应该是constantValue=id，hasConstantValue=true。

![](/img/mybatis-npe/12.png)

测试过程中，我们发现多个线程调用的对象实际是同一个，如下图中的ASTConst@6075。

![](/img/mybatis-npe/13.png)

根据多线程常见问题处理经验来看，如果多线程操作同一个对象，则要注意其是否存在成员变量。如果有，那还要注意是否做了并发可见性处理。

于是我们看下代码

![](/img/mybatis-npe/14.png)

![](/img/mybatis-npe/15.png)

那我们指导了这里有并发问题，那就好容易模拟了。我们只要在第一个线程中保持一种状态，然后暂停操作。再在另外一个线程中去特定的操作

步骤中正常变更数据。最后再放开第一个线程继续往下执行。由于第一个线程的成员变量已经发生了变化，所以后续的结果就不再是预想的那样

了。

于是就有了如下结果

![](/img/mybatis-npe/16.png)

模拟的关键在于：

1. 多线程操作同一个服务
2. 第一个线程在判断语句处等待第二个线程变更条件值，this.constantValueCalculated变量初始化为false，等第二个线程变更后变为true
3. 第一个线程继续往下执行
4. 第二个线程变更了成员变量的值，this.hasConstantValue变量初始化为false，但是被变更为true，然后等待第一个线程执行
5. 第一个线程用刚更新的值去判断，返回了null值，也就导致了后续的NPE异常

<span style="color:blue">*注意：以上说的“等待”只是模拟说法，实际情况会由CPU控制，执行顺序不定。恰巧出现了以上执行流程，则会出现NPE问题。*<span>

# 升级版处理逻辑

在Mybatis的3.4.5版本中，程序采用了volatile修饰符来定义变量，并且在使用上面也注意了赋值的先后顺序。

![](/img/mybatis-npe/17.png)

![](/img/mybatis-npe/18.png)

# 结论

建议升级mybatis，版本是3.3.0+，提及到新的ognl处理逻辑修复此问题，但是我们要考虑在经过充分测试的前提下进行升级。







