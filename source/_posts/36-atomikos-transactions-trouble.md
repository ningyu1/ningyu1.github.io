---
toc : true
title : "atomikos jta(xa) transaction问题：Already mapped: xxxx"
description : "atomikos jta(xa) transaction问题：Already mapped: xxxx"
tags : [
    "atomikos",
	"transaction",
	"jta xa",
	"Already mapped"

]
date : "2017-11-02 15:52:36"
categories : [
    "trouble shooting"
]
menu : "main"
---

# 目录：
1. [问题现象](#trouble)
2. [问题分析](#troubleshooting)
3. [修改验证](#validation)
4. [解决方案](#solutions)
5. [总结](#summed)

## <a name="trouble">问题现象</a>

库存中心在压测过程中会时不时的报错，错误如下：

```
2017-11-02 11:38:37.620 [DubboServerHandler-10.27.69.168:20888-thread-156] ERROR xx.xx.inv.service.impl.OptionApiImpl - java.lang.IllegalStateException: Already mapped: 10.27.69.168.tm150959391756909559
xx.xx.exception.BizException: java.lang.IllegalStateException: Already mapped: 10.27.69.168.tm150959391756909559
        at xx.xx.inv.service.impl.OptionApiImpl.invWmsOption(OptionApiImpl.java:290) ~[inv-api-impl-1.0.1-SNAPSHOT.jar:na]
        at com.alibaba.dubbo.common.bytecode.Wrapper1.invokeMethod(Wrapper1.java) [na:2.5.3]
        at com.alibaba.dubbo.rpc.proxy.javassist.JavassistProxyFactory$1.doInvoke(JavassistProxyFactory.java:46) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.proxy.AbstractProxyInvoker.invoke(AbstractProxyInvoker.java:72) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.InvokerWrapper.invoke(InvokerWrapper.java:53) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.AccessLogFilter.invoke(AccessLogFilter.java:199) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.ExceptionFilter.invoke(ExceptionFilter.java:64) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.TimeoutFilter.invoke(TimeoutFilter.java:42) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.monitor.support.MonitorFilter.invoke(MonitorFilter.java:75) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.dubbo.filter.TraceFilter.invoke(TraceFilter.java:78) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.ContextFilter.invoke(ContextFilter.java:60) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.GenericFilter.invoke(GenericFilter.java:112) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.ClassLoaderFilter.invoke(ClassLoaderFilter.java:38) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.filter.EchoFilter.invoke(EchoFilter.java:38) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.rpc.protocol.dubbo.DubboProtocol$1.reply(DubboProtocol.java:108) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.remoting.exchange.support.header.HeaderExchangeHandler.handleRequest(HeaderExchangeHandler.java:84) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.remoting.exchange.support.header.HeaderExchangeHandler.received(HeaderExchangeHandler.java:170) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.remoting.transport.DecodeHandler.received(DecodeHandler.java:52) [dubbo-2.5.3.jar:2.5.3]
        at com.alibaba.dubbo.remoting.transport.dispatcher.ChannelEventRunnable.run(ChannelEventRunnable.java:82) [dubbo-2.5.3.jar:2.5.3]
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145) [na:1.7.0_79]
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615) [na:1.7.0_79]
        at java.lang.Thread.run(Thread.java:745) [na:1.7.0_79]
Caused by: java.lang.IllegalStateException: Already mapped: 10.27.69.168.tm150959391756909559
        at com.atomikos.icatch.imp.TransactionServiceImp.setTidToTx(TransactionServiceImp.java:191) ~[transactions-4.0.0.jar:na]
        at com.atomikos.icatch.imp.TransactionServiceImp.createCT(TransactionServiceImp.java:277) ~[transactions-4.0.0.jar:na]
        at com.atomikos.icatch.imp.TransactionServiceImp.createCompositeTransaction(TransactionServiceImp.java:783) ~[transactions-4.0.0.jar:na]
        at com.atomikos.icatch.imp.CompositeTransactionManagerImp.createCompositeTransaction(CompositeTransactionManagerImp.java:393) ~[transactions-4.0.0.jar:na]
        at com.atomikos.icatch.jta.TransactionManagerImp.begin(TransactionManagerImp.java:271) ~[transactions-jta-4.0.0.jar:na]
        at com.atomikos.icatch.jta.TransactionManagerImp.begin(TransactionManagerImp.java:249) ~[transactions-jta-4.0.0.jar:na]
        at com.atomikos.icatch.jta.UserTransactionImp.begin(UserTransactionImp.java:72) ~[transactions-jta-4.0.0.jar:na]
        at org.springframework.transaction.jta.JtaTransactionManager.doJtaBegin(JtaTransactionManager.java:874) ~[spring-tx-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.transaction.jta.JtaTransactionManager.doBegin(JtaTransactionManager.java:831) ~[spring-tx-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.transaction.support.AbstractPlatformTransactionManager.getTransaction(AbstractPlatformTransactionManager.java:373) ~[spring-tx-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.transaction.interceptor.TransactionAspectSupport.createTransactionIfNecessary(TransactionAspectSupport.java:447) ~[spring-tx-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:277) ~[spring-tx-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:96) ~[spring-tx-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179) ~[spring-aop-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:656) ~[spring-aop-4.3.6.RELEASE.jar:4.3.6.RELEASE]
        at xx.xx.inv.service.impl.VoucherExecutor$$EnhancerBySpringCGLIB$$a5e2dd9c.doWms(<generated>) ~[inv-api-impl-1.0.1-SNAPSHOT.jar:na]
        at xx.xx.inv.service.impl.OptionApiImpl.invWmsOption(OptionApiImpl.java:286) ~[inv-api-impl-1.0.1-SNAPSHOT.jar:na]
        ... 30 common frames omitted
```

## <a name="troubleshooting">问题分析</a>

跟踪源码：com.atomikos.icatch.imp.TransactionServiceImp.setTidToTx()

```
private void setTidToTx ( String tid , CompositeTransaction ct )
        throws IllegalStateException
{
    synchronized ( tidToTransactionMap_ ) {
        if ( tidToTransactionMap_.containsKey ( tid.intern () ) )
            throw new IllegalStateException ( "Already mapped: " + tid );
        tidToTransactionMap_.put ( tid.intern (), ct );
        ct.addSubTxAwareParticipant(this); // for GC purposes
    }
}
```

发现在tidToTransactionMap_中存在tid重复的情况，这个方法判断如果出现重复报：Already mapped: ${tid}，继续跟踪找到tid生成的地方

```
public CompositeTransaction createCompositeTransaction ( long timeout ) throws SysException
{
    if ( !initialized_ ) throw new IllegalStateException ( "Not initialized" );
    if ( maxNumberOfActiveTransactions_ >= 0 &&
         tidToTransactionMap_.size () >= maxNumberOfActiveTransactions_ ) {
        throw new IllegalStateException ( "Max number of active transactions reached:" + maxNumberOfActiveTransactions_ );
    }
     
    String tid = tidmgr_.get ();
    Stack<CompositeTransaction> lineage = new Stack<CompositeTransaction>();
    // create a CC with heuristic preference set to false,
    // since it does not really matter anyway (since we are
    // creating a root)
    CoordinatorImp cc = createCC ( null, tid, true, false, timeout );
    CompositeTransaction ct = createCT ( tid, cc, lineage, false );
    return ct;
}
```

tid是通过tidmgr_.get ();这个东西生成的，那我们进去看一下生成的代码具体是什么？

```
private final static int MAX_LENGTH_OF_NUMERIC_SUFFIX = 8 + 5;
private final static int MAX_COUNTER_WITHIN_SAME_MILLIS = 32000;
 
 
private final String commonPartOfId; //name of server
private int lastcounter;
 
public String get()
{
    incrementAndGet();
    StringBuffer buffer = new StringBuffer();
    return buffer.append(commonPartOfId).
                  append(System.currentTimeMillis()).
                  append(getCountWithLeadingZeroes ( lastcounter )).
                  toString() ;
}
 
private synchronized void incrementAndGet() {
    lastcounter++;
    if (lastcounter == MAX_COUNTER_WITHIN_SAME_MILLIS) lastcounter = 0;
}
```

那极其有可能get的时候在极端的情况下生成的id是相同的，incrementAndGet方法是synchronized 理论上不会有并发问题，但是lastcounter这个属性不是支持并发的对象，在get方法中先调用同步方法incrementAndGet对属性lastcounter++，后面buffer在append的时候直接使用的是属性lastcounter属性的值，很有可能问题就出在这里，那让我们使用btrace验证一下。


通过btrace对get方法拦截验证发现确实在极端的情况下会有多个线程生成同一个tid，如下：

```
[DubboServerHandler-10.27.69.168:20888-thread-177] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391749109556
[DubboServerHandler-10.27.69.168:20888-thread-156] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391749509557
[DubboServerHandler-10.27.69.168:20888-thread-156] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391756909559
[DubboServerHandler-10.27.69.168:20888-thread-177] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391756909559
[DubboServerHandler-10.27.69.168:20888-thread-155] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391780109560
[DubboServerHandler-10.27.69.168:20888-thread-155] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391786909561
[DubboServerHandler-10.27.69.168:20888-thread-112] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391791609562
[DubboServerHandler-10.27.69.168:20888-thread-197] - com.atomikos.util.UniqueIdMgr.get()-->10.27.69.168.tm150959391794109563
```

出现了两个tm150959391756909559，那就能断定肯定是这块出问题，那如何解决呢?

首先查看我们使用的atomikos transaction的版本号 – > 4.0.0

去maven官服上搜索transaction的版本信息:[http://mvnrepository.com/artifact/com.atomikos/atomikos-util](http://mvnrepository.com/artifact/com.atomikos/atomikos-util "maven repostory")

![1.png](/img/atomikos-transactions/1.png)


看来有更高的版本，那我们下载一个版本看一下get的代码是否发生了变化，我们从4.0.1版本开始查看。

```
public String get()
{
  StringBuffer buffer = new StringBuffer();
  String id = this.commonPartOfId + System.currentTimeMillis() + getCountWithLeadingZeroes(incrementAndGet());
  return id;
}
 
private synchronized int incrementAndGet()
{
  this.lastcounter += 1;
  if (this.lastcounter == 32000) {
    this.lastcounter = 0;
  }
  return this.lastcounter;
}
```

从上面代码可以发现跟4.0.0的代码是有变化的

<span style="color:red">**一、4.0.0版本在incrementAndGet方法同步的对lastcounter++之后，在拼接id的时候是直接使用属性lastcounter进行拼接**</span>
<span style="color:red">**二、4.0.1版本在incrementAndGet方法同步的对lastcounter++之后直接将lastcounter值返回，在拼接的时候使用返回的lastcounter值来进行拼接**</span>

从代码上看好像是为了解决这个问题，那我们还需要进一步验证

首先先找到官方的chang log看是否有明确的版本升级描述中fixed并发tid的bug，翻atomikos的[官网站点](https://www.atomikos.com/Blog/ExtremeTransactions4dot0dot1)

![2.png](/img/atomikos-transactions/2.png)

功夫不负有心人找到了fixed记录，接下来就需要升级程序然后再进行实际压测过程去校验是否真的解决了这个问题

## <a name="validation">修改验证</a>

升级atomikos transactions版本–>4.0.1,打包程序发布进行压力测试
压测场景：
4个仓，一个仓10个线程，一个线程2000单，一单2个商品，一个商品6个sku
<span style="color:red">**压测后再没有Already mapped: xxxx的错误爆出，库存扣除也是正确的。**</span>

## <a name="solutions">解决方案</a>

<span style="color:red">**升级atomikos transactions版本–>4.0.1**</span>

## <a name="summed">总结</a>

在使用任何第三方框架都是存在风险，就看如何进行权衡，出现问题能否hold的住，当出现由于使用第三方框架带来的问题时。
1. 首先要彻底的分析出问题的原因
2. 其次就去社区或者官网或者问作者是否bug已经fixed。
3. 上面的都尝试之后如果还不能解决，要么寻找替换方案，要么修改源码。
<span style="color:red">**能使用官网升级的版本解决问题尽量升级版本解决，第三步的方法虽然不推荐，但是在特定的环境也是一个兜底的方案。**</span>

