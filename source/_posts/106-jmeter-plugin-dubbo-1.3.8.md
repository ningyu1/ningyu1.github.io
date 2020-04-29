---
toc : true
title : "[Enhancement]Enumeration type support, Dubbo Plugin for Apache JMeter - V1.3.8"
description : "[Enhancement]Enumeration type support, Dubbo Plugin for Apache JMeter - V1.3.8"
tags : [
	"jmeter",
	"dubbo",
	"test",
	"Dubbo可视化测试工具",
	"Jmeter对Dubbo接口进行可视化压力测试",
	"Dubbo Jmeter插件"
]
date : "2018-12-18 13:57:21"
categories : [
    "test"
]
menu : "main"
---

# 项目地址

[github: jmeter-plugin-dubbo](https://github.com/dubbo/jmeter-plugins-dubbo) 

[码云: jmeter-plugin-dubbo]( https://gitee.com/ningyu/jmeter-plugins-dubbo)

# [V1.3.8](https://github.com/dubbo/jmeter-plugins-dubbo/releases/tag/V1.3.8)

# What is new:

1. Enumeration type support. [#34](https://github.com/dubbo/jmeter-plugins-dubbo/issues/34)
2. Support group to zookeeper,redis registration center. [#33](https://github.com/dubbo/jmeter-plugins-dubbo/issues/33)

# 新版改进：

1. 支持枚举类型参数。[#34](https://github.com/dubbo/jmeter-plugins-dubbo/issues/34)
2. zookeeper、redis作为注册中心时增加group支持。 [#33](https://github.com/dubbo/jmeter-plugins-dubbo/issues/33)

<span style="color:blue">*ps. 参数类型支持：枚举类型以及参数对象内属性为枚举类型*</span>

# 截图

![](/img/jmeter-plugins-dubbo-1-3-8/1.png)

<span style="color:blue">*ps. dubbo:registry group: 服务注册分组，跨组的服务不会相互影响，也无法相互调用，适用于环境隔离。*</span>

<span style="color:blue">*具体查看[dubbo文档](http://dubbo.apache.org/zh-cn/docs/user/references/xml/dubbo-registry.html)*</span>