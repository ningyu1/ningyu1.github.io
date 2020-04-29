---
toc : true
title : "Spring框架-事务管理注意事项"
description : "Spring框架-事务管理注意事项"
tags : [
    "Spring",
	"Transaction"

]
date : "2017-08-26 16:40:36"
categories : [
    "Java",
	"Spring"
]
menu : "main"
---


## 常见事务问题

1. 事务不起作用
	* 可能是配置不起效，如扫描问题
2. 事务自动提交了（批量操作中）
	* 可能是在没事务的情况下，利用了数据库的隐式提交

## 事务配置说明

通常情况下我们的`Spring Component`扫描分为两部分，一部分是`Spring Servlet(MVC)`，一部分是其他`Context Config`的内容。主要扫描`Annotation`定义，包括`@Controller`、`@Autowired`、`@Resource`、`@Service`、`@Component`、`@Repository`等。

`Spring Servlet`部分的扫描配置可以通过`web.xml`中`DispatchServlet`的`init-param`节点配置确定。

`Context Config`部分的扫描配置为非以上配置的其他`Spring`配置文件确定。

为了能够使用事务，需要防止因`Spring Servlet`的扫描导致`@Service`事务配置失效。可以调整`DispatchServlet`中的配置文件，排除对`@Service`的扫描。

配置如下：
```xml
<context:component-scan base-package="com.jiuyescm.xxx">
	<context:exclude-filter type="annotation" expression="org.springframework.stereotype.Service" />
</context:component-scan>
```

## 如何通过日志判断事务是否已经被Spring所管理？

1. 在logback或者log4j中对org.springframework.aop、org.springframework.transaction、org.springframework.jdbc、org.mybatis.spring.transaction进行DEBUG级别日志跟踪（开发期）
2. 查看日志中是否有事务管理、开启、提交、回滚等字符，如：
```log
DEBUG o.m.spring.transaction.SpringManagedTransaction - JDBC Connection [com.alibaba.druid.proxy.jdbc.ConnectionProxyImpl@28cfe912] will be managed by Spring
```

3. 没有被控制的时候，日志如下：
```log
DEBUG o.m.spring.transaction.SpringManagedTransaction - JDBC Connection [com.alibaba.druid.proxy.jdbc.ConnectionProxyImpl@28cfe912] will not be managed by Spring
```

## 如何通过程序判断是否存在事务？

```java
boolean flag = TransactionSynchronizationManager.isActualTransactionActive();
```

返回true，则在事务控制下，否则不在控制下

## 什么时候做了隐式提交？

在没有容器事务的情况下，系统会尝试隐时提交。

![spring1](/img/spring-transaction/1.png)

## 开发建议：

1. 所有Service代码中设置Class级别的@Transactional，并设置为只读，开发时可以很容易发现误数据库操作的动作。如：@Transactional(readOnly=true)。
2. 所有Service代码中Public的方法设置@Transactional，并根据实际情况设置Propagation，可以设置为REQUIRED。
3. 对于有异常产生可能的情况下，根据情况选择合适的rollbackFor，默认情况下可以设置对Exception.class或BizException.class进行控制。
4. 尽可能减少嵌套的使用方法（Service call Service），采用传统的Controller-》Service-》Repository(DAO)的模型。

如果需要深入了解Transaction的流程，请自行翻阅和跟踪Spring和Mybatis相关代码。

以下是嵌套事务的各种情况下的执行结果（前提数据库的AutoCommit为true）

|编号|External（Service）|Internal（Service）|Result|Memo|
|:---|:-----------------|:------------------|:-----|:---|
|1|No Transactional|No Transactional|All Committed|Auto Commit = True|
|2|No Transactional|Class Level ReadOnly Transactional|External Committed Internal TransientDataAccessResourceException|Can't update table|
|3|No Transactional|Transactional(REQUIRED)|All Committed| |
|4|No Transactional|Transactional(REQUIRES_NEW)|All Committed| |
|5|No Transactional|Transactional(SUPPORTS)|All Committed| |
|6|No Transactional|Transactional(MANDATORY)|External Committed Internal IllegalTransactionStateException|Must under transaction|
|7|No Transactional|Transactional(NOT_SUPPORTED)|All Committed| |
|8|No Transactional|Transactional(NEVER)|All Committed| |
|9|No Transactional|Transactional(NESTED)|All Committed| |
|10|No Transactional|Transactional(REQUIRED) rollackFor=Exception.class IOException|External Committed Internal Rollbacked| |
|11|No Transactional|Transactional(REQUIRED) rollbackFor=RuntimeException.class IOException|All Committed| |
|12|No Transactional|Transactional(REQUIRED)|rollbackFor=Exception.class RuntimeException|External Committed Internal Rollbacked|
|13|No Transactional|Transactional(REQUIRED)|rollbackFor=RuntimeException.class RuntimeException	|External Committed Internal Rollbacked|
|14|Class Level ReadOnly Transactional|No Transactional|External TransientDataAccessResourceException|Can't update table|
|15|Class Level ReadOnly Transactional|Class Level ReadOnly Transactional |External TransientDataAccessResourceException|Can't update table|
|16|Transactional(REQUIRED)|No Transactional|All Committed| |
|17|Transactional(REQUIRES_NEW)|No Transactional|All Committed| |
|18|Transactional(SUPPORTS)|No Transactional|All Committed| |
|19|Transactional(MANDATORY)|No Transactional|External IllegalTransactionStateException|Must under transaction|
|20|Transactional(NOT_SUPPORTED)|No Transactional|All Committed| |
|21|Transactional(NEVER)|No Transactional|All Committed| |
|22|Transactional(NESTED)|No Transactional|All Committed| |
|23|Transactional(REQUIRED)|Transactional(REQUIRED)|All Committed| |
|24|Transactional(REQUIRED)|Transactional(REQUIRES_NEW)|All Committed| |
|25|Transactional(REQUIRED)|Transactional(SUPPORTS)|All Committed| |
|26|Transactional(REQUIRED)|Transactional(MANDATORY)|All Committed| |
|27|Transactional(REQUIRED)|Transactional(NOT_SUPPORTED)|All Committed| |
|28|Transactional(REQUIRED)|Transactional(NEVER)|External Rollbacked Internal IllegalTransactionStateException|Must under transaction|
|29|Transactional(REQUIRED)|Transactional(NESTED)|All Committed| |
|30|Transactional(REQUIRED)|rollackFor=Exception.class Transactional(REQUIRED) rollackFor=Exception.class IOException|All Rollbacked| |
|31|Transactional(REQUIRED)|rollackFor=Exception.class Transactional(REQUIRED) rollbackFor=RuntimeException.class IOException|All Rollbacked| |
|32|Transactional(REQUIRED)|rollackFor=RuntimeException.class Transactional(REQUIRED) rollackFor=Exception.class IOException|All Rollbacked UnexpectedRollbackException| |
|33|Transactional(REQUIRED)|rollackFor=RuntimeException.class Transactional(REQUIRED) rollbackFor=RuntimeException.class IOException|All Committed| |
|34|Transactional(REQUIRED)|rollackFor=Exception.class Transactional(REQUIRED) rollackFor=Exception.class RuntimeException|All Rollbacked| |
|35|Transactional(REQUIRED)|rollackFor=Exception.class Transactional(REQUIRED) rollbackFor=RuntimeException.class RuntimeException|All Rollbacked| |
|36|Transactional(REQUIRED)|rollackFor=RuntimeException.class Transactional(REQUIRED) rollackFor=Exception.class RuntimeException|All Rollbacked| |
|37|Transactional(REQUIRED)|rollackFor=RuntimeException.class Transactional(REQUIRED) rollbackFor=RuntimeException.class RuntimeException|All Rollbacked| | 
|38|Transactional(REQUIRED)|rollackFor=Exception.class Transactional(REQUIRED) rollackFor=Exception.class IOException Catch IOException|All Committed| |
|39|Transactional(REQUIRED)|rollackFor=Exception.class Catch IOExceptio Transactional(REQUIRED) rollbackFor=Exception.class IOException|All Rollbacked UnexpectedRollbackException| |
|40|Transactional(REQUIRED)|rollackFor=Exception.class Catch IOException Transactional(REQUIRED) rollbackFor=RuntimeException.class IOException|All Committed| |

其他情况按照事务是否开启和是否抛出（捕获）对应异常来判断结果。



