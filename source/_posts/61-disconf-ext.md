---
toc : true
title : "扩展Disconf支持Global共享配置，简化业务应用参数配置"
description : "扩展Disconf支持Global共享配置，简化业务应用参数配置"
tags : [
	"disconf",
	"ucm"
]
date : "2018-02-11 11:26:49"
categories : [
	"ucm"
]
menu : "main"
---


当我们使用统一配置中心（`UCM`）后或许都会出现这种烦恼，项目中的配置项目多，当项目引用到基础中间件时都要增加基础中间件的配置，例如：zk参数、redis参数、rpc参数、loadbalance参数、mq参数、等。这些配置都是基础的中间件配置，应该做成共享的方式让所有APP都共享，而并不是在用的时候再去APP中添加，Global的配置基础中间件团队维护即可。

### 为什么要有公共共享的配置？

因为在APP配置中有很多是公共的配置，如果没有Global就需要在自己的APP中配置这些配置信息，导致APP中配置信息过多不好维护，公共的配置信息修改需要通知各业务APP修改自己APP中的配置，没有达到一处修改，各处使用的目标。

### 这时候有朋友就会问我了如果做成全局共享配置，那不同项目需要修改全局某个参数怎么办呢？

这个需求也很正常，比如loadbalance参数确实需要根据不同项目的具体情况去配置参数，对于这种问题其实很好解决，我们可以使用APP中的配置去覆盖Global配置，也就是说当APP中的配置项与Global配置项相同的情况下，以APP的配置为主即可。

这样一来APP的配置生效的优先级为：Local conf > Project conf > Global conf，当出现相同配置项以APP自身的配置为主去覆盖。

增加了Global的支持后，APP中的配置减少了，避免了一些由于配置导致的错误，也可以通过Global的方式去规范APP的配置，让业务开发不关心公共配置的细节，在使用的时候直接使用无需维护。

`Disconf`作为一个比较老牌的`UCM`在这方面支持的并不好，它并没有共享配置这个概念，这样一来公共的配置就需要在每个APP中都要配置一份，操作起来很烦人。

# 那我们如何来解决这个问题？我们能否扩展`Disconf`让其支持`Global`共享配置呢？

## 扩展思路

在加载properties的时候，也就是ReloadablePropertiesFactoryBean的locations，给前面默认加一个GlobalProp项目的索引项：global（使用disconf的新建配置项，而不是配置文件），这个索引项的值是所有global配置文件的名称，使用","分隔，例如：

```
global-dubbo.properties,global-redis.properties,global-zookeeper.properties,global-sso.properties,global-mq.properties,global-fastdfs.properties,global-elasticsearch.properties 
```

让disconf下载配置文件的时候优先下载global的配置文件，在properties加载的时候优先加载global的配置，这样当发生重复项时后加载的会覆盖前面的信息，从而达到了我们上面的需求，当APP中修改了某个global配置应该以APP的配置项为主。

接下来就让我们看一下具体扩展了哪些类？

Disconf的扩展点做的不是那么的好，因此扩展起来有些麻烦，我使用的是比较暴力的方式，直接使用原包的类在名称后加Ext然后修改代码，使用的时候使用Ext的类替代即可，这种方式的弊端是升级`Disconf`的时候很麻烦。

## Disconf扫描管理

```
com.baidu.disconf.client.DisconfMgrBean
扩展一个
com.baidu.disconf.client.DisconfMgrBeanExt

com.baidu.disconf.client.DisconfMgrBeanSecond
扩展一个
com.baidu.disconf.client.DisconfMgrBeanSecondExt
```

## Reloadable Properties

```
com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBean
扩展一个
com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBeanExt
```

可以增加一个开关从而支持启用global的自由度，默认是开启的。

下面来看一下扩展后的具体使用方法如下

## 项目地址

[disconf-client-ext](https://github.com/ningyu1/disconf-client-ext) 

<a href="https://github.com/ningyu1/disconf-client-ext/releases"><img src="https://img.shields.io/github/release/ningyu1/disconf-client-ext.svg?style=social&amp;label=Release"></a>&nbsp;<a href="https://github.com/ningyu1/disconf-client-ext/stargazers"><img src="https://img.shields.io/github/stars/ningyu1/disconf-client-ext.svg?style=social&amp;label=Star"></a>&nbsp;<a href="https://github.com/ningyu1/disconf-client-ext/fork"><img src="https://img.shields.io/github/forks/ningyu1/disconf-client-ext.svg?style=social&amp;label=Fork"></a>&nbsp;<a href="https://github.com/ningyu1/disconf-client-ext/watchers"><img src="https://img.shields.io/github/watchers/ningyu1/disconf-client-ext.svg?style=social&amp;label=Watch"></a> <a href="http://www.gnu.org/licenses/gpl-3.0.html"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg"></a>

## disconf-client-ext的使用

* 依赖disconf版本：2.6.32
* pom中引入disconf-client-ext依赖
* 修改disconf配置
	* 替换`com.baidu.disconf.client.DisconfMgrBean` --> `com.baidu.disconf.client.DisconfMgrBeanExt`
	* 替换`com.baidu.disconf.client.DisconfMgrBeanSecond` --> `com.baidu.disconf.client.DisconfMgrBeanSecondExt`
	* 替换`com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBean` --> `com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBeanExt`
	* 修改locations中配置文件，只保留项目自己的配置文件，例如

```
<bean id="disconfNotReloadablePropertiesFactoryBean" class="com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBeanExt">
	<property name="locations">
		<list>
			<value>classpath:/jdbc.properties</value>
		</list>
	</property>
</bean>
```

* <span style="color:red">关闭global共享配置（默认是开启的）</span>

```
<bean id="disconfNotReloadablePropertiesFactoryBean" class="com.baidu.disconf.client.addons.properties.ReloadablePropertiesFactoryBeanExt">
	<property name="locations">
		<list>
			<value>classpath:/jdbc.properties</value>
		</list>
	</property>
	<property name="globalShareEnable" value="false" />
</bean>
```

* 最后一步添加global项目到`Disconf`

![](/img/disconf-ext/1.png)


世界和平，Keep Real!



