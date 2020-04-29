---
toc : true
title : "Google Guava官方教程（中文版）"
description : "Google Guava官方教程（中文版）"
tags : [
    "Guava"

]
date : "2015-03-09 17:34:36"
categories : [
    "Java"
]
menu : "main"
---


Guava 中文是石榴的意思，该项目是 Google 的一个开源项目，包含许多 Google 核心的 Java 常用库。

## 引言

Guava工程包含了若干被Google的 Java项目广泛依赖 的核心库，例如：集合 [collections] 、缓存 [caching] 、原生类型支持 [primitives support] 、并发库 [concurrency libraries] 、通用注解 [common annotations] 、字符串处理 [string processing] 、I/O 等等。 所有这些工具每天都在被Google的工程师应用在产品服务中。

查阅Javadoc并不一定是学习这些库最有效的方式。在此，我们希望通过此文档为Guava中最流行和最强大的功能，提供更具可读性和解释性的说明。

译文格式说明

Guava中的类被首次引用时，都会链接到Guava的API文档。如：Optional。
Guava和JDK中的方法被引用时，一般都会链接到Guava或JDK的API文档，一些人所共知的JDK方法除外。如：Optional.of(T), Map.get(key)。
译者对文档的额外说明以斜体显示，并且以“译者注：”开始。

## 目录

### 1. 基本工具 [Basic utilities]

让使用Java语言变得更舒适
* 使用和避免null：null是模棱两可的，会引起令人困惑的错误，有些时候它让人很不舒服。很多Guava工具类用快速失败拒绝null值，而不是盲目地接受
* 前置条件: 让方法中的条件检查更简单
* 常见Object方法: 简化Object方法实现，如hashCode()和toString()
* 排序: Guava强大的”流畅风格比较器”
* Throwables：简化了异常和错误的传播与检查

### 2. 集合[Collections]

Guava对JDK集合的扩展，这是Guava最成熟和为人所知的部分
* 不可变集合: 用不变的集合进行防御性编程和性能提升。
* 新集合类型: multisets, multimaps, tables, bidirectional maps等
* 强大的集合工具类: 提供java.util.Collections中没有的集合工具
* 扩展工具类：让实现和扩展集合类变得更容易，比如创建Collection的装饰器，或实现迭代器

### 3. 缓存[Caches]

Guava Cache：本地缓存实现，支持多种缓存过期策略

### 4. 函数式风格[Functional idioms]

Guava的函数式支持可以显著简化代码，但请谨慎使用它

### 5. 并发[Concurrency]

强大而简单的抽象，让编写正确的并发代码更简单
* ListenableFuture：完成后触发回调的Future
* Service框架：抽象可开启和关闭的服务，帮助你维护服务的状态逻辑

### 6. 字符串处理[Strings]

非常有用的字符串工具，包括分割、连接、填充等操作

### 7. 原生类型[Primitives]

扩展 JDK 未提供的原生类型（如int、char）操作， 包括某些类型的无符号形式

### 8. 区间[Ranges]

可比较类型的区间API，包括连续和离散类型

### 9. I/O

简化I/O尤其是I/O流和文件的操作，针对Java5和6版本

### 10. 散列[Hash]

提供比Object.hashCode()更复杂的散列实现，并提供布鲁姆过滤器的实现

### 11. 事件总线[EventBus]

发布-订阅模式的组件通信，但组件不需要显式地注册到其他组件中

### 12. 数学运算[Math]

优化的、充分测试的数学工具类

### 13. 反射[Reflection]

Guava 的 Java 反射机制工具类


参考: [Google Guava官方教程（中文版）](http://ifeve.com/google-guava/ "Google Guava官方教程（中文版）")