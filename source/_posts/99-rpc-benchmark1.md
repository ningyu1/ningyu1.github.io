---
toc : true
title : "如何编写高性能的 RPC 框架"
description : "如何编写高性能的 RPC 框架"
tags : [
	"rpc-benchmark"
]
date : "2018-09-19 12:01:00"
categories : [
    "rpc"
]
menu : "main"
---

最近看相关rpc-benchmark相关的东西发现这篇文章挺好的，所以转载出来，下面是文章出处。

作者：鲁小憨
链接：https://www.jianshu.com/p/7182b8751e75
來源：简书
简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。


在 [RPC Benchmark Round 1](https://www.jianshu.com/p/18c95649b1a4) 中，[Turbo](https://github.com/hank-whu/turbo-rpc) 性能炸裂表现强悍，并且在 listUser 这一项目中，取得了 10x dubbo 性能的好成绩。本文将介绍 [Turbo](https://github.com/hank-whu/turbo-rpc) 强悍性能背后的原理，并探讨如何编写高性能的 RPC 框架。

# 过早的优化是万恶之源？

这句话是 The Art of Computer Programming 作者，图领奖得主 Donald Knuth 大神说的。不过对于框架设计者而言，这句话并不正确。在设计一款高性能的基础框架时，必须始终重视性能优化，并将性能测试贯穿于整个设计开发过程中。这方面做到极致的类库有 [Disruptor](https://github.com/LMAX-Exchange/disruptor) [JCTools](https://github.com/JCTools/JCTools) [Agrona](https://github.com/real-logic/agrona) [DSL-JSON](https://github.com/ngs-doo/dsl-json) 等等，这几个高性能类库都坚持一个原则：不了解性能的外部类库坚决不用，如果现有的类库不能满足性能要求，那就重新设计一个。作为 [Turbo](https://github.com/hank-whu/turbo-rpc) 的设计者，我也尽量坚持这一原则，努力做到 Benchmark 驱动开发。

# JMH 让 Benchmark 驱动开发成为可能

在 JMH 出现之前，要对某个类库进行微基准性能测试是一件非常困难的事情。很难保证公平的测试条件，预热次数难以确定，预热效果也不好观察。JMH 的出现让性能测试变得 标准化 简单化，也让 Benchmark 驱动开发成为可能。Turbo 在开发过程中用 JMH 进行了充分的 Benchmark，以确定核心环节的性能开销，选择合适的实现方案。更多关于 JMH 的介绍请参考下面的链接：

* [OpenJDK: jmh](http://openjdk.java.net/projects/code-tools/jmh/)
* [JMH - Java Microbenchmark Harness](http://tutorials.jenkov.com/java-performance/jmh.html)
* [ImportNew JMH简介](http://www.importnew.com/12548.html)

# RPC 的主要流程

1. 客户端 获取到 UserService 接口的 Refer: userServiceRefer
2. 客户端 调用 userServiceRefer.verifyUser(email, pwd)
3. 客户端 获取到 请求方法 和 请求数据
4. 客户端 把 请求方法 和 请求数据 序列化为 传输数据
5. 进行网络传输
6. 服务端 获取到 传输数据
7. 服务端 反序列化获取到 请求方法 和 请求数据
8. 服务端 获取到 UserService 的 Invoker: userServiceInvoker
9. 服务端 userServiceInvoker 调用 userServiceImpl.verifyUser(email, pwd) 获取到 响应结果
10. 服务端 把 响应结果 序列化为 传输数据
11. 进行网络传输
12. 客户端 接收到 传输数据
13. 客户端 反序列化获取到 响应结果
14. 客户端 userServiceRefer.verifyUser(email, pwd) 返回 响应结果

整个流程中对性能影响比较大的环节有：序列化[4, 7, 10, 13]，方法调用[2, 3, 8, 9, 14]，网络传输[5, 6, 11, 12]。本文后续内容将着重介绍这3个部分。

# 序列化方案

Java 世界最常用的几款高性能序列化方案有 [Kryo](https://github.com/EsotericSoftware/kryo) [Protostuff](https://github.com/protostuff/protostuff) [FST](https://github.com/RuedigerMoeller/fast-serialization) [Jackson](https://github.com/FasterXML/jackson) [Fastjson](https://github.com/alibaba/fastjson)。只需要进行一次 Benchmark，然后从这5种序列化方案中选出性能最高的那个就行了。[DSL-JSON](https://github.com/ngs-doo/dsl-json) 使用起来过于繁琐，不在考虑之列。[Colfer](https://github.com/pascaldekloe/colfer) [Protocol](https://developers.google.com/protocol-buffers/) [Thrift](https://thrift.apache.org/) 因为必须预先定义描述文件，使用起来太麻烦，所以不在考虑之列。至于 Java 自带的序列化方案，早就因为性能问题被大家所抛弃，所以也不考虑。下面的表格列出了在考虑之列的5种序列化方案的性能。

* [User](https://github.com/hank-whu/rpc-benchmark/blob/master/benchmark-base/src/main/java/benchmark/bean/User.java) 序列化+反序列化 性能

|framework|	thrpt (ops/ms)	|size|
| --- | --- | --- |
|protostuff|	1654	|240|
|kryo|	1288|	296|
|fst	|1101|	263|
|jackson|	959|	385|
|fastjson|	603	|378|

* 包含15个 [User](https://github.com/hank-whu/rpc-benchmark/blob/master/benchmark-base/src/main/java/benchmark/bean/User.java) 的 [Page](https://github.com/hank-whu/rpc-benchmark/blob/master/benchmark-base/src/main/java/benchmark/bean/Page.java) 序列化+反序列化 性能

|framework|	thrpt (ops/ms)	|size|
| --- | --- | --- |
|kryo	|143|	2080|
|fst	|118|	3495|
|protostuff|	98|	3920|
|jackson	|71|	5711|
|fastjson	|40|	5606|

从这个 benchmark 中可以得出明确的结论：二进制协议的 protostuff kryo fst 要比文本协议的 jackson fastjson 有明显优势；文本协议中，jackson(开启了afterburner) 要比 fastjson 有明显的优势。

无法确定的是：3个二进制协议到底哪个更好一些，毕竟 速度 和 size 对于 RPC 都很重要。直观上 kryo 或许是最佳选择，而且 kryo 也广受各大型系统的青睐。不过最终还是决定把这3个类库都留作备选，通过集成传输模块后的 Benchmark 来决定选用哪个。

|framework|	exist op/ms	|create op/ms	|get op/ms|	list op/ms|
| --- | --- | --- | --- | --- |
|proto	|103.92	|89.50	|83.33|	21.17|
|kryo|	99.23	|76.71|	73.89|	25.68|
|fst|	102.33	|76.24|	78.81|	23.30|

最终的结果也还是各有千秋难以抉择，所以 [Turbo](https://github.com/hank-whu/turbo-rpc) 保留了 protostuff 和 kryo 的实现，并允许用户自行替换为自己的实现。

# 方法调用

可用的 动态方法调用 方案有：Reflection ClassGeneration MethodHandle。Reflection 是最古老的技术，据说性能不佳。ClassGeneration 动态类生成，从原理上说应该是跟直接调用一样的性能。MethodHandle 是从 Java 7 开始出现的技术，据说能达到跟直接调用一样的性能。实际结果如下：

|type|	thrpt (ops/us)	|
| --- | --- | 
|direct|	1062|
|javassist|	920|
|methodHandle|	430|
|reflection|	337|

结论非常明显：使用类生成技术的 [javassist](http://jboss-javassist.github.io/javassist/) 跟直接调用几乎一样的性能，就用 [javassist](http://jboss-javassist.github.io/javassist/) 了。


MethodHandle 表现并没有宣传的那么好，怎么回事？原来 MethodHandle 只有在明确知道调用 参数数量 参数类型 的情况下才能调用高性能的 invokeExact(Object... args)，所以它并不适合作为动态调用的方案。

```
As is usual with virtual methods, source-level calls to invokeExact and invoke compile to an invokevirtual instruction. More unusually, the compiler must record the actual argument types, and may not perform method invocation conversions on the arguments. Instead, it must push them on the stack according to their own unconverted types. The method handle object itself is pushed on the stack before the arguments. The compiler then calls the method handle with a symbolic type descriptor which describes the argument and return types.
refer: https://docs.oracle.com/javase/7/docs/api/java/lang/invoke/MethodHandle.html
```

# 网络传输

[Netty](https://github.com/netty/netty) 已经成为事实上的标准，所有主流的项目现在使用的都是 [Netty](https://github.com/netty/netty)。[Mina](http://mina.apache.org/) [Grizzly](https://github.com/javaee/grizzly) 已经失去市场，所以也就不用考虑了。还好也不至于这么无聊，[Aeron](https://github.com/real-logic/aeron) 的闪亮登场让 Netty 多了一个有力的竞争对手。Aeron 是一个可靠高效的 UDP 单播 UDP 多播和 IPC 消息传递工具。性能是消息传递中的关键。Aeron 的设计旨在达到 高吞吐量 低开销 和 低延迟。实际效果到底如何呢？很遗憾，在 [RPC Benchmark Round 1](https://www.jianshu.com/p/18c95649b1a4) 中的表现一般。跟他们开发团队沟通后，最终确认其[无法对超过 64k 的消息进行 zero-copy 处理](https://github.com/real-logic/aeron/issues/432)，我觉得这可能是 Aeron 表现不佳的一个原因。Aeron 或许更适合 微小消息 极端低延迟 的场景，而不适用于更加通用的 RPC 场景。所以暂时还没有出现能够跟 Netty 一争高下的通用网络传输框架，现阶段 Netty 依然是 RPC 系统的最佳选择。

* existUser 判断某个 email 是否存在

|framework|	thrpt (ops/ms)	|avgt (ms)|	p90 (ms)|	p99 (ms)|
|--|--|--|--|--|
|turbo-rpc|	107.05|	0.28|	0.40|	0.87|
|netty|	99.81|	0.32|	0.40|	0.52|
|jupiter|	73.07|	0.44|	0.66|	1.49|
|undertow|	70.38|	0.45|	1.16|	2.17|
|turbo-rest|	68.49|	0.44|	1.17|	2.15|
|undertow-async|	62.65|	0.49|	1.14|	2.41|
|dubbo-kryo|	57.35|	0.53|	0.67|	1.02|
|rapidoid|	52.96|	0.61|	1.32|	2.51|
|dubbo|	52.12|	0.54|	0.67|	0.92|
|motan|	44.96|	0.71|	1.15|	2.47|
|aeron|	43.46|	0.90|	1.32|	5.10|
|grpc|	38.97|	0.84|	1.07|	1.31|
|thrift|	27.25|	1.59|	0.16|	64.87|
|hprose|	26.24|	1.26|	1.53|	2.01|
|springwebflux|	22.39|	1.42|	2.27|	3.19|
|springboot|	12.54|	1.68|	2.38|	13.63|

# 消息格式

我们先来看一下 Dubbo 的消息格式

```
public class RpcInvocation implements Invocation, Serializable {
    private String methodName;
    private Class<?>[] parameterTypes;
    private Object[] arguments;
    ...
}
```

可以说是非常经典的设计，Client 必须告知 Server 要调用的 方法名称 参数类型 参数。Server 获取到这3个参数后，通过 方法名称 com.alibaba.service.auth.UserService.verifyUser 和
参数类型 (String, String) 获取到 Invoker，然后通过 Invoker 实际调用 userServiceImpl 的 verifyUser(String, String) 方法。其他的众多 RPC 框架也都采取了这一经典设计。

但是，这是正确的做法吗？当然不是，这种做法非常浪费空间，每次请求消息体的大概内存布局应该是下面的样子：

```
public boolean verifyUser(String email, String pwd);

|com.alibaba.service.auth.UserService.verifyUser|java.lang.String,java.lang.String|实际的参数|
```

啰里啰嗦的，浪费了 80 byte 来定义 方法 和 参数，并没有比 http+json 的方式高效多少。实际的 [性能测试](https://www.jianshu.com/p/18c95649b1a4) 也证明了这一点，undertow+jackson 要比 dubbo motan 的成绩都要好。

那什么才是正确的做法？[Turbo](https://github.com/hank-whu/turbo-rpc) 在消息格式上做出了非常大的改变。

```
public class Request implements Serializable {
    private int requestId;
    private int serviceId;
    private MethodParam methodParam;
    ...
}
```

大致的内存布局：

```
public boolean verifyUser(String email, String pwd);
|int|int|实际的参数|
```

高效多了，只用了 4 byte 就做到了 方法 和 参数 的定义。大大减小了 传输数据 的 size，同时 int 类型的 serviceId 也降低了 Invoker 的查找开销。

看到这里，有同学可能会问：那岂不是要为每个方法定义一个唯一 id ？
答案是不需要的，[Turbo](https://github.com/hank-whu/turbo-rpc) 解决了这一问题，详情参考 [TurboConnectService](https://github.com/hank-whu/turbo-rpc/blob/master/turbo-rpc/src/main/java/rpc/turbo/common/TurboConnectService.java) 。

# MethodParam 简介

[MethodParam](https://github.com/hank-whu/turbo-rpc/blob/master/turbo-rpc/src/main/java/rpc/turbo/param/MethodParamClassFactory.java) 才是 [Turbo](https://github.com/hank-whu/turbo-rpc) 性能炸裂的真正原因。其基本原理是利用 ClassGeneration 对每个 Method 都生成一个 [MethodParam](https://github.com/hank-whu/turbo-rpc/blob/master/turbo-rpc/src/main/java/rpc/turbo/param/MethodParamClassFactory.java) 类，用于对方法参数的封装。这样做的好处有：

1. 减少基本数据类型的 装箱 拆箱 开销
2. 序列化时可以省略掉很多类型描述，大大减小 传输消息 的 size
3. 使 Invoker 可以高效调用 被代理类 的方法
4. 统一 RPC 和 REST 的数据模型，简化 序列化 反序列化 实现
5. 大大加快 json 格式数据 反序列化 速度

```
//方法 test(long id, int value) 将会生成下面的 MethodParam 类:     
public class TestService_test_2_MethodParam implements MethodParam {
    private long id;
    private int value;
     
    public long $param0() { return this.id; }
    public int $param1() { return this.value; }

    //... getters and setters
     
    public TestService_test_2_MethodParam(long id, int value) {
        this.id = id;
        this.value= value;
    }
}
```

# 序列化的进一步优化

大部分 RPC 框架的 序列化 反序列化 过程都需要一个中间的 bytes

```
序列化过程：User > bytes > ByteBuf
反序列化过程：ByteBuf > bytes > User
```

而 [Turbo](https://github.com/hank-whu/turbo-rpc) 砍掉了中间的 bytes，直接操作 ByteBuf，实现了 序列化 反序列化 的 zero-copy，大大减少了 内存分配 内存复制 的开销。具体实现请参考 [ProtostuffSerializer](https://github.com/hank-whu/turbo-rpc/blob/master/turbo-protostuff/src/main/java/rpc/turbo/serialization/protostuff/ProtostuffSerializer.java) 和 [Codec](https://github.com/hank-whu/turbo-rpc/tree/master/turbo-rpc/src/main/java/rpc/turbo/transport/server/rpc/codec)。

对于已知类型和已知字段，[Turbo](https://github.com/hank-whu/turbo-rpc) 都尽量采用 手工序列化 手工反序列化 的方式来处理，以进一步减少性能开销。

# ObjectPool

常见的几个 ObjectPool 实现性能都很差，反而很容易成为性能瓶颈。Stormpot 性能强悍，不过存在偶尔死锁的问题，而且作者也停止维护了。HikariCP 性能不错，不过其本身是一款数据库连接池，用作 ObjectPool 并不称手。我的建议是尽量避免使用 ObjectPool，转而使用替代技术。更重要的是 Netty 的 Channel 是线程安全的，并不需要使用 ObjectPool 来管理。只需要一个简单的容器来存储 Channel，用的时候使用 负载均衡策略 选出一个 Channel 出来就行了。

|framework|	thrpt (ops/us)|
|--|--|
|ThreadLocal|	685.418|
|Stormpot|	272.934|
|HikariCP|	139.126|
|SegmentLock|	19.415|
|Vibur|	4.668|
|CommonsPool2|	1.107|
|CommonsPool|	0.276|

# 基础类库优化

除了上述的关键流程优化，[Turbo](https://github.com/hank-whu/turbo-rpc) 还做了大量基础类库的优化

* AtomicMuiltInteger 多个 int 的原子性操作
* ConcurrentArrayList 无锁并发 List 实现，比 CopyOnWriteArrayList 的写入开销低，O(1) vs O(n)
* ConcurrentIntToObjectArrayMap 以 int 数组为底层实现的无锁并发 Map，读多写少情况下接近直接访问字段的性能，读多写多情况下是 ConcurrentHashMap 性能的 5x
* ConcurrentIntegerSequencer 快速序号生成器，并发环境下是 AtomicInteger 性能的10x
* ObjectId 全局唯一 id 生成器，是 Java 自带 UUID 性能的 200x
* HexUtils 查表 + 批量操作，是 Netty 和 Guava 实现的 2x~5x
* URLEncodeUtils 基于 HexUtils 实现，是 Java 和 Commons 实现的 2x，Guava 实现的 1.1x (Guava 只有 urlEncode 实现，无 urlDecode 实现)
* ByteBufUtils 实现了高效的 ZigZag 写入操作，最高可达通常实现的 4x

上面的内容仅介绍了作者认为重要的东西，更多内容请直接查看 [Turbo 源码](https://github.com/hank-whu/turbo-rpc/)

# 不足之处

* 有很多优化是毫无价值的，Donald Knuth 大神说得很对
* 强制必须使用 CompletableFuture 作为返回值导致了一些性能开销
* 滥用 ClassGeneration，而且并没有考虑类的卸载，这方面需要改进
* 实现了 [UnsafeStringUtils](https://github.com/hank-whu/turbo-rpc/blob/master/turbo-utils/src/main/java/rpc/turbo/util/UnsafeStringUtils.java)，这是个危险的黑魔法实现，需要重新思考下
* 对性能的追求有点走火入魔，导致了很多地方的设计过于复杂
