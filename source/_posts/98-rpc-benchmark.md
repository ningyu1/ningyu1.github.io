---
toc : true
title : "怎样对RPC进行有效的性能测试"
description : "怎样对RPC进行有效的性能测试"
tags : [
	"rpc-benchmark"
]
date : "2018-09-18 18:16:00"
categories : [
    "rpc"
]
menu : "main"
---

最近看相关rpc-benchmark相关的东西发现这篇文章挺好的，所以转载出来，下面是文章出处。

作者：鲁小憨
链接：https://www.jianshu.com/p/cbcdf05eaa5c
來源：简书
简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。


在 [RPC Benchmark Round 1](https://www.jianshu.com/p/18c95649b1a4) 中 [turbo](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Fturbo-rpc) 的成绩一骑绝尘，实力碾压众 rpc 框架。对此，很多人表示不服气，认为作者既是运动员又是裁判员有失公平。所以我认为有必要解释一下 [rpc-benchmark](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Frpc-benchmark) 的公正性，以及为什么 [turbo](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Fturbo-rpc) 能够如此强悍。

# 参考对象

[rpc-benchmark](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Frpc-benchmark) 灵感源自 [techempower-benchmarks](https://link.jianshu.com/?t=https%3A%2F%2Fwww.techempower.com%2Fbenchmarks%2F)，为了能够评测众多服务器框架，[techempower-benchmarks](https://link.jianshu.com/?t=https%3A%2F%2Fwww.techempower.com%2Fbenchmarks%2F) 提供了6个测试用例：

* JSON serialization

This test exercises the framework fundamentals including keep-alive support, request routing, request header parsing, object instantiation, JSON serialization, response header generation, and request count throughput.

* Single database query

This test exercises the framework's object-relational mapper (ORM), random number generator, database driver, and database connection pool.

* Multiple database queries

This test is a variation of Test #2 and also uses the World table. Multiple rows are fetched to more dramatically punish the database driver and connection pool. At the highest queries-per-request tested (20), this test demonstrates all frameworks' convergence toward zero requests-per-second as database activity increases.

* Fortunes

This test exercises the ORM, database connectivity, dynamic-size collections, sorting, server-side templates, XSS countermeasures, and character encoding.

* Database updates

This test is a variation of Test #3 that exercises the ORM's persistence of objects and the database driver's performance at running UPDATE statements or similar. The spirit of this test is to exercise a variable number of read-then-write style database operations.

* Plaintext

This test is an exercise of the request-routing fundamentals only, designed to demonstrate the capacity of high-performance platforms in particular. Requests will be sent using HTTP pipelining. The response payload is still small, meaning good performance is still necessary in order to saturate the gigabit Ethernet of the test environment.

[techempower-benchmarks](https://link.jianshu.com/?t=https%3A%2F%2Fwww.techempower.com%2Fbenchmarks%2F) 规则都是公开的，代码都是开放的。任何人觉得xx框架写得不好，配置有问题，都可以来提交自己的 Pull Request 。一句话，不服气的话就来提交代码。

# 测试用例

不过 [techempower-benchmarks](https://link.jianshu.com/?t=https%3A%2F%2Fwww.techempower.com%2Fbenchmarks%2F) 对比的都是服务器框架，并不能用来测试 rpc 的性能，作为学习模仿者，我创建了 [rpc-benchmark](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Frpc-benchmark) 这个项目。 [rpc-benchmark](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Frpc-benchmark) 提供了4个测试用例：

* boolean existUser(String email), 判断某个 email 是否存在
输入是很短的字符串，输出是 bool 值，这个测试用例用于衡量小 Request 小
Response 的性能。

* boolean createUser(User user), 添加一个 用户
输入是一个 User 的对象，输出是 bool 值，这个测试用例用于衡量大 Request 小 Response 的性能。

* User getUser(long id), 根据 id 获取一个用户
输入是一个 long 类型的值，输出是 User 对象，这个测试用例用于衡量小 Request 大 Response 的性能。

* Page<User> listUser(int pageNo), 获取用户列表
输入是 int 类型的值，输出是一个包含15个 User 的列表，这个测试用例用于衡量小 Request 超大 Response 的性能。

这4个测试用例构成了一个基本的业务逻辑： 用户注册管理。非常具有代表性，并且没有脱离现实使用场景。有些测试用例可能会注重衡量字符串的传输速度，从4字节 64字节 ... 64k字节 依次测起，这样的测试用例就过于脱离现实，没有太多的实际意义。毕竟作为 rpc 框架，除了传输速度，序列化速度其实也是非常重要的。而仅仅用字符串来测试仅能测试出框架的传输速度，并不能有效衡量序列化的性能，也不能衡量整体的 rpc 性能。

# 测试工具

因为每个 rpc 框架都有自己的 序列化协议 传输协议，所以 [rpc-benchmark](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2Fhank-whu%2Frpc-benchmark) 不能像 [techempower-benchmarks](https://link.jianshu.com/?t=https%3A%2F%2Fwww.techempower.com%2Fbenchmarks%2F) 一样直接使用 wrk 作为测试工具，只能每个框架都编写测试用的 客户端实现。

客户端实现 使用的工具是JMH，这个工具 Java 开发团队自己也在使用。正确的性能测试在之前并不是一件简单的事情，JMH 的出现让性能测试真正的 标准化 简单化。更多关于 JMH 的介绍可以参考下面的链接。

* [JMH - Java Microbenchmark Harness](https://link.jianshu.com/?t=http%3A%2F%2Ftutorials.jenkov.com%2Fjava-performance%2Fjmh.html)
* [ImportNew JMH简介](https://link.jianshu.com/?t=http%3A%2F%2Fwww.importnew.com%2F12548.html)

# 测试方法

测试的过程是先进行10次预热，然后才开始真正的3次测试（JMH的“每次”执行实际上是执行很多次，更好的翻译其实应该是“每轮”）。刚开始使用的是5次预热，但是后来发现 http 传输协议的 undertow grpc 等框架都比较慢热，需要更多的预热次数。完整的测试要跑起来依然有点费劲，需要配置很多环境。不过如果你只是想研究下某个框架的代码实现的话，完全可以更简单一些。拉下代码来直接导入到 Eclipse/IDEA ，配置好hosts，启动 Server，然后启动相应的 Client 就好了。

# 为什么把 undertow springboot netty 也作为了测试对象

按照 wiki 的[定义](https://link.jianshu.com/?t=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FRemote_procedure_call)，这三个确实不能认为是 rpc ，不过简单封装之后他们都可以作为 rpc 使用。加入这几个更多的是为给 rpc 框架的实现者提供一个参考，作为基础的协议层性能是怎么样的？作为springcloud 的底层实现，springboot 其实代表了springcloud 的性能。undertow 证明了 http+json 并不比 tcp+binary 慢太多，其速度甚至比 dubbo motan 还要快不少。同时也是为了告诉喷子们，并不是说你用了高性能的 netty+protopuff 就能比 turbo 快，turbo 能碾压众框架并不只是靠简单的拼积木就能做到的。

# 不足之处

仅1个客户端32个线程其实是非常不严谨的，正确的做法应该是从1个线程一直到32k个线程逐步增加，从1台客户端机器到1000台客户端机器逐步增加（客户端数量 线程数量 应该是一个笛卡尔积）。不过每轮测试实在都太耗费时间了，而且阿里云的服务器也不便宜，所以只能作罢。后续如果有云服务器厂商赞助的话，可以考虑把这块给做起来。

# turbo为什么如此强悍

篇幅有限写不开了，下篇再说吧。