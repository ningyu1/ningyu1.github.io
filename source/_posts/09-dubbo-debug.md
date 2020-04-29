---
toc : true
title : "Dubbo本地调试最优方式，本地Server端调用本地Client端"
description : "Dubbo本地调试最优方式，本地Server端调用本地Client端"
tags : [
    "dubbo",
	"debug",
	"rpc"
]
date : "2016-12-20 14:32:41"
categories : [
    "dubbo"
]
menu : "main"
---


# 分布式应用的调试总是比常规项目开发调试起来要麻烦很多。

# 我们还在为搞不清自己请求的服务是本地服务还是服务器服务而苦恼吗？

# 我们还在为配置文件被修改导致服务器上版本服务不正常而苦恼吗？

接下来我介绍一个Dubbo在多环境调试的最优调试方式，在介绍之前先说一下我们现在的调试方式。

不好的方式（现在的方式）：
现在本地调试，需要修改DubboServer.xml和DubboClient.xml配置文件

```
将文件中的
dubbo:registry protocol="zookeeper" address="${dubbo.registry}" />
修改为
<dubbo:registry address="N/A" />
```
这种方式的弊端：

1. 开发总是不注意将修改为address="N/A"的文件提交到svn，在其他环境打包run起来，总是没有Export Service。
2. 文件经常被改来改去容易冲突，冲突解决不好容易丢失配置。
3. 无法很好的将本地调试和各环境的相互依赖分离开

最优的方式：

1. 创建一个properties文件，名字可以随便命名，我命名为：dubbo-local.properties，这个文件可以放在任何地方。该文件不提交到svn，我建议不要放在工程目录里以避免自己提交了都不知道，建议放在用户目录下${user.home}(不知道用户目录的自己去 度娘、谷哥、必硬)
2. dubbo-local.properties文件内容如下：
	```
	<!--注册中心变量 -->
	dubbo.registry=N/A
	 
	<!--以下是你们DubboServer.xml中配置的需要Export Service，这里我建议你有几个要Export Service都配置在这里，后面是请求本地的地址
	地址格式：dubbo://ip:port，这里需要注意的是，需要修改为自己dubbo服务的端口 -->
	com.domain.imprest.api.IImprestRecordService=dubbo://localhost:20812
	com.domain.imprest.api.IImprestRequestService=dubbo://localhost:20812
	com.domain.imprest.api.IImprestTrackService=dubbo://localhost:20812
	com.domain.imprest.api.IImprestWriteoffService=dubbo://localhost:20812
	com.domain.imprest.api.IImprestIOCollectService=dubbo://localhost:20812
	com.domain.imprest.api.ISystemService=dubbo://localhost:20812
	com.domain.imprest.api.IImprestDeptService=dubbo://localhost:20812
	```
3. 接下来启动你的Dubbo服务，在启动之前需要添加一下启动参数

![dubbo1](/img/dubbo/1.png)
```
参数：-Ddubbo.properties.file
值：dubbo-local.properties文件的本地地址，绝对地址
```
4. 接下来启动你的web服务，在启动之前需要添加一下启动参数

![dubbo2](/img/dubbo/2.png)
```
参数：-Ddubbo.resolve.file
值：dubbo-local.properties文件的本地地址，绝对地址
```
**ps.当你不想连接本地服务调试时，只需将启动参数去掉即可，无需修改配置文件，让配置文件一直保持清爽干净。
以后你就可以安心的本地调试你的程序了，再也不会因为服务没有Export出去、配置文件被修改而焦头烂额。**


# Dubbo Plugin for Apache JMeter

Dubbo Plugin for Apache JMeter是用来在Jmeter里更加方便的测试Dubbo接口而开发的插件，[马上使用](https://ningyu1.github.io/site/post/60-jmeter-plugins-dubbo-support)

# 项目地址

[github: jmeter-plugin-dubbo](https://github.com/ningyu1/jmeter-plugins-dubbo) 

<a href="https://github.com/ningyu1/jmeter-plugins-dubbo/releases"><img src="https://img.shields.io/github/release/ningyu1/jmeter-plugins-dubbo.svg?style=social&amp;label=Release"></a>&nbsp;<a href="https://github.com/ningyu1/jmeter-plugins-dubbo/stargazers"><img src="https://img.shields.io/github/stars/ningyu1/jmeter-plugins-dubbo.svg?style=social&amp;label=Star"></a>&nbsp;<a href="https://github.com/ningyu1/jmeter-plugins-dubbo/fork"><img src="https://img.shields.io/github/forks/ningyu1/jmeter-plugins-dubbo.svg?style=social&amp;label=Fork"></a>&nbsp;<a href="https://github.com/ningyu1/jmeter-plugins-dubbo/watchers"><img src="https://img.shields.io/github/watchers/ningyu1/jmeter-plugins-dubbo.svg?style=social&amp;label=Watch"></a> <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>

[码云: jmeter-plugin-dubbo]( https://gitee.com/ningyu/jmeter-plugins-dubbo)

|release|star|fork|license|
|:-:|:-:|:-:|:-:|
|[V1.2.2](https://gitee.com/ningyu/jmeter-plugins-dubbo/releases/V1.2.0)|[![star](https://gitee.com/ningyu/jmeter-plugins-dubbo/badge/star.svg?theme=white)](https://gitee.com/ningyu/jmeter-plugins-dubbo/stargazers)|[![fork](https://gitee.com/ningyu/jmeter-plugins-dubbo/badge/fork.svg?theme=white)](https://gitee.com/ningyu/jmeter-plugins-dubbo/members)|[MIT](https://opensource.org/licenses/MIT)|

# 相关博文

* [Dubbo接口如何在Jmeter中测试，自研Dubbo Plugin for Apache JMeter](https://ningyu1.github.io/site/post/60-jmeter-plugins-dubbo-support/)
* [Bug Fix Version V1.1.0, Dubbo Plugin for Apache JMeter](https://ningyu1.github.io/site/post/66-jmeter-plugin-dubbo-bugfix/)
* [New Version V1.2.0, Dubbo Plugin for Apache JMeter](https://ningyu1.github.io/site/post/68-jmeter-plugin-dubbo-1.2.0/)
