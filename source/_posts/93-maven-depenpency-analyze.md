---
toc : true
title : "通过对Maven的依赖分析剔除无用的jar引用"
description : "通过对Maven的依赖分析剔除无用的jar引用"
tags : [
	"maven",
	"dependency:analyze"
]
date : "2018-07-11 14:11:00"
categories : [
    "maven"
]
menu : "main"
---

当项目开发维护了一段时间时，经常会有项目打包速度慢，jar依赖多，依赖关系错综复杂，这种问题是项目维护最常见的问题，由于开发人员在bugfix或者feature开发时往往只是往项目中添加jar依赖，那我们如何分析出项目中哪些依赖是用到的，哪些依赖是不用的？

使用[Maven analyze](http://maven.apache.org/plugins/maven-dependency-plugin/analyze-mojo.html)来进行分析

使用如下命令：

```
mvn dependency:analyze
```

会输出如下的日志：

```
[INFO] --- maven-dependency-plugin:2.8:analyze (default-cli) @ xxxproject ---
[WARNING] Used undeclared dependencies found:
[WARNING]    org.springframework:spring-beans:jar:4.0.0.RELEASE:compile
[WARNING]    org.springframework:spring-context:jar:4.0.0.RELEASE:compile
[WARNING] Unused declared dependencies found:
[WARNING]    com.alibaba:dubbo:jar:2.5.3:compile
[WARNING]    com.baidu.disconf:disconf-client:jar:2.6.32:compile
[WARNING]    org.mybatis:mybatis:jar:3.2.7:compile
[WARNING]    org.mybatis:mybatis-spring:jar:1.2.2:compile
[WARNING]    mysql:mysql-connector-java:jar:5.1.41:compile
[WARNING]    com.alibaba:druid:jar:1.0.9:compile
[WARNING]    com.github.sgroschupf:zkclient:jar:0.1:compile
[WARNING]    org.apache.zookeeper:zookeeper:jar:3.4.6:compile
[WARNING]    org.springframework:spring-jdbc:jar:4.0.0.RELEASE:compile
[WARNING]    org.slf4j:log4j-over-slf4j:jar:1.7.5:compile
[WARNING]    org.slf4j:jcl-over-slf4j:jar:1.7.5:runtime
[WARNING]    ch.qos.logback:logback-classic:jar:1.0.13:compile                         
```

我们就来说一下日志中的`Used undeclared dependencies found`和`Unused declared dependencies found`

## Used undeclared dependencies found

这个是指某些依赖的包在代码中有用到它的代码，但是它并不是直接的依赖（就是说没有在pom中直接声明），是通过引入传递下来的包。

举个例子：

`project`在`pom`中声明了`A.ja`r的依赖（没有声明`B.jar`的依赖）
`A.jar`的依赖关系：`A.jar` -> `B.jar`
通过`mvn dependency:analyze`出现
`[WARNING] Used undeclared dependencies found: B.jar`
就说明`project`中的代码用到了`B.jar`的代码
这个时候你就可以把`B.jar`直接声明在pom中

## Unused declared dependencies found

这个是指我们在pom中声明了依赖，但是在实际代码中并没有用到这个包！也就是多余的包。
这个时候我们就可以把这个依赖从pom中剔除。

<span style="color:blue">
*但是这里我们需要注意：
这里说的实际代码没有用到，指的是在main/java和test里没有用的，但是并不是意味着真的没有用到这些包，有可能配置文件中引用或者其他扩展点自动加载这些包，所以我们在删除依赖的时候一定要小心，做好备份，因为这类引用maven是分析不出来的。*
</span>
