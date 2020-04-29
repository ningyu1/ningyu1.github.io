---
toc : true
title : "SLF4J和Logback日志框架详解"
description : "SLF4J和Logback日志框架详解"
tags : [
    "SLF4J",
    "Logback"

]
date : "2015-04-10 10:15:03"
categories : [
    "Java",
	"Logger"
]
menu : "main"
---


## 本文讲述SLF4J和Logback日志框架。

![logger1](/img/logger/1.png)

SLF4J是一套简单的日志外观模式的Java API，帮助在项目部署时对接各种日志实现。
LogBack在运行时使用JMX帮助修改日志配置，在生产状态下无需重启应用程序。

## SLF4J

SLF4J是简单的日志外观模式框架，抽象了各种日志框架例如Logback、Log4j、Commons-logging和JDK自带的logging实现接口。它使得用户可以在部署时使用自己想要的日志框架。SLF4J是轻量级的，在性能方面几乎是零消耗的。

SLF4J没有替代任何日志框架，它仅仅是标准日志框架的外观模式。如果在类路径下除了SLF4J再没有任何日志框架，那么默认状态是在控制台输出日志。

## Logback

Logback是Log4j的改进版本，而且原生支持SLF4J（因为是同一作者开发的），因此从其它日志框架如Log4j或JDK的logging迁移到Logback是完全可行的。

由于Logback原生支持SLF4J，因此Logback＋SLF4J的组合是日志框架的最佳选择，比SLF4J+其它日志框架的组合要快一些。而且Logback的配置可以是XML或Groovy代码。

注意一个重要的特性，Logback通过JMX修改日志配置（比如日志级别从Debug调整到INFO），可以从JMX控制台直接操作，无需重启应用程序。

此外，Logback的异常堆栈跟踪的信息，有助于调试。

```java
java.lang.NullPointerException: null  
at com.fimt.poc.LoggingSample.(LoggingSample.java:16) [classes/:na]  
at com.fimt.poc.LoggingSample.main(LoggingSample.java:23) [fimt-logging-poc-1.0.jar/:1.0
```

## SLF4J API用法

* 从org.slf4j包导入Logger和LoggerFactory

```java
import org.slf4j.Logger;  
import org.slf4j.LoggerFactory;  
```
* 声明日志类

```java
private final Logger logger = LoggerFactory.getLogger(LoggingSample.class);  
```

* 使用debug、warn、info、error方法并跟踪适合的参数。

所有的方法默认都使用字符串作为输入。
```java
logger.info("This is sample info statement");  
```

## SLF4J结合Logback

在pom.xml包含下面的依赖：它会自动包含所有的依赖包logback-core、slf4j-api……
```xml
<dependency>  
  <groupId>ch.qos.logback</groupId>  
  <artifactId>logback-classic</artifactId>  
  <version>1.0.7</version>  
</dependency>  
```

SLF4J能用于现有的日志框架如Log4j、Commons-logging、java.util.logging(JUL)。

## SLF4J结合Log4j

在pom.xml包含下面的依赖

```xml
<dependency>  
  <groupId>org.slf4j</groupId>  
  <artifactId>slf4j-log4j12</artifactId>  
  <version>1.7.2</version>  
</dependency>  
```

## SLF4J结合JUL (java.util.logging)

在pom.xml包含下面的依赖

```xml
<dependency>  
  <groupId>org.slf4j</groupId>  
  <artifactId>slf4j-jdk14</artifactId>  
  <version>1.7.2</version>  
</dependency> 
```