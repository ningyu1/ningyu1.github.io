---
toc : true
title : "Dubbo接口如何在Jmeter中测试，自研Dubbo Plugin for Apache JMeter"
description : "Dubbo接口如何在Jmeter中测试，自研Dubbo Plugin for Apache JMeter"
tags : [
	"jmeter",
	"dubbo",
	"test",
	"Dubbo可视化测试工具",
	"Jmeter对Dubbo接口进行可视化压力测试",
	"Dubbo Jmeter插件"
]
date : "2018-02-09 15:39:49"
categories : [
    "test"
]
menu : "main"
---

最近公司测试需要对`Dubbo`的`RPC`接口进行测试，测试工具使用的是`Jmeter`，按照常规的做法需要包装一个`Java`请求，再配合`Jmeter`的`Java Sample`去做测试，这种做法是最简单最普遍的，但是这个方法不够灵活和方便，那我们能不能写一个`Jmeter Plugin`来解决这个问题？让`Dubbo RPC`接口测试更为方便一些？

那我们先了解一下Jmeter的插件机制

# Jmeter Plugin

先来看一下`Jmeter`的核心组件

1. `Sample` 取样器，这个是最主要的组件，测试的内容主要是靠Sample来实现，我们常见的Sample有，`HttpSample`、`FTPSample`、`JavaSample`、`SMTPSample`、`LDAPSample`等。
2. `Timer` 定时器，主要用于配置sample之间的等待时间，可以查看：`org.apache.jmeter.timers.RandomTimer`
3. `ConfigElement` 配置组件，主要用于定义前置配置。如数据库连接，csv输入数据集等。主要功能是将配置转换为变量设置到JMeter context中。
4. `Assertion` 验证Sampler的结果是否符合预期
5. `PostProcessor` 一般用于对Sampler结果进行二次加工
6. `Visualizer` 将sampler的结果进行可视化展示。
7. `Controller` 对sampler进行逻辑控制。
8. `SampleListener` 负责处理监听，基于事件机制。一般用于保存sampler的结果等耗费时间的操作。

Jmeter的插件机制比较简单，Jmeter提供了扩展类来支持自定义插件的开发。
继承`org.apache.jmeter.samplers.gui.AbstractSamplerGui`和`org.apache.jmeter.samplers.AbstractSampler`就可以完成一个插件开发。

# JMeter的GUI机制

由于`Jmeter`是一个基于`Swing`的GUI工具,所以开发插件需要对`Java Swing GUI`框架有一定了解。 `JMeter`内部有两种GUI的实现方式。

## 第一种方式：

直接继承JMeterGUIComponent接口的抽象实现类:

```
org.apache.jmeter.config.gui.AbstractConfigGui
org.apache.jmeter.assertions.gui.AbstractAssertionGui
org.apache.jmeter.control.gui.AbstractControllerGui
org.apache.jmeter.timers.gui.AbstractTimerGui
org.apache.jmeter.visualizers.gui.AbstractVisualizer
org.apache.jmeter.samplers.gui.AbstractSamplerGui
```

## 通过Swing的Bean绑定机制

前者的好处是自由度高，可定制性强，但需要开发者关心GUI控件布局,以及从控件到Model的转换。后者基本不需要开发者接触到GUI层的东西，定义好`Bean`以及`BeanInfo`即可。但`SampleListener`不支持`BeanInfo`方式定义。

**ps.如果java swing比较熟悉的话推荐使用第一种方式，自由度高。**


下面是我写的插件DubboSample，主要用于Dubbo RPC接口测试。

## Dubbo Plugin for Apache JMeter

jmeter-plugin-dubbo项目已经transfer到dubbo group下

[github: jmeter-plugin-dubbo](https://github.com/dubbo/jmeter-plugins-dubbo) 

[码云: jmeter-plugin-dubbo]( https://gitee.com/ningyu/jmeter-plugins-dubbo)

## DubboSample使用

### 支持Jmeter版本

Jmeter版本：3.0

### 插件安装

插件包可以去`github`上下载。将插件包放入Jmeter的lib的ext下。

```
${Path}\apache-jmeter-3.0\lib\ext
```

如果使用的是:`jmeter-plugins-dubbo-1.0.0-SNAPSHOT-jar-with-dependencies.jar`包含所有依赖。

如果使用的是：`jmeter-plugins-dubbo-1.0.0-SNAPSHOT.jar`需要自定添加插件的依赖包，推荐使用上面的包，依赖包版本如下：

```
dubbo-2.5.3.jar
javassist-3.15.0-GA.jar
zookeeper-3.4.6.jar
zkclient-0.1.jar
jline-0.9.94.jar
netty-3.7.0-Final.jar
slf4j-api-1.7.5.jar
log4j-over-slf4j-1.7.5.jar
```

### 插件使用

启动`Jmeter`添加`DubboSample`如下图：

![](/img/jmeter-plugins-dubbo/1.png)

添加后能看到`DubboSample`的具体操作页面，如下图：

![](/img/jmeter-plugins-dubbo/2.png)

根据上图提示传入值即可。

接口以及接口依赖包请添加到`classpath`下，可以放在`apache-jmeter-3.0\lib\ext`下，也可以通过下图方式添加：

![](/img/jmeter-plugins-dubbo/3.png)

### 运行结果

![](/img/jmeter-plugins-dubbo/4.png)

![](/img/jmeter-plugins-dubbo/5.png)

![](/img/jmeter-plugins-dubbo/6.png)

### 注意事项

1. 当使用zk，address填入zk地址（集群地址使用","分隔）,使用dubbo直连，address填写直连地址和服务端口
2. `timeout`：服务方法调用超时时间(毫秒)
3. `version`：服务版本，与服务提供者的版本一致
4. `retries`：远程服务调用重试次数，不包括第一次调用，不需要重试请设为0
5. `cluster`：集群方式，可选：failover/failfast/failsafe/failback/forking
6. 接口需要填写类型完全名称，含包名
7. 参数支持任何类型，包装类直接使用`java.lang`下的包装类，小类型使用：`int、float、shot、double、long、byte、boolean、char`，自定义类使用类完全名称。
8. 参数值，基础包装类和基础小类型直接使用值，例如：int为1，boolean为true等，自定义类与`List`或者`Map`等使用json格式数据。
9. 更多dubbo参数查看官方文档：[http://dubbo.io/books/dubbo-user-book/references/xml/dubbo-reference.html](http://dubbo.io/books/dubbo-user-book/references/xml/dubbo-reference.html)

到这里插件的就介绍完了。世界和平、keep real！