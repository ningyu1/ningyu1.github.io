---
toc : true
title : "疑似Batch处理事务问题，保存了该回滚的数据"
description : "疑似Batch处理事务问题，保存了该回滚的数据"
tags : [
	"mybatis",
	"batch"
]
date : "2019-02-20 14:34:21"
categories : [
    "mybatis"
]
menu : "main"
---

这篇文章转自公司内网wiki中一篇不错的问题分析文章，

# 问题描述

1. 两个事物， 在第一个事务报错是则执行第二个事务
2. 两个事物都是执行下面的批量操作
3. 两个事务的批量操作是插入到相同的两张表中，如下代码
4. 第一个事务预计在第一个表中插入3条记录， 第二个表中插入3条记录，但是第一个表的第一个记录就违反了约束，报错异常；
5. 第一个事务失败后，执行第二个事务，第二个事务插入两个表中各一条记录。
6. 实际结果：第一个表有一条记录（第二个事务中插入的），第二个表中有4条记录（除了第二个事务中的一条，还有第一个事务中的3条数据）

![](/img/mybatis-batch/1.png)

问题点是在第一个事务抛异常回滚了，第一个表成功回滚，但是第二个事务将第一个事务中的第二个表的数据提交了。

# 问题原因

1. 我们说明批量操作是指：如下的样例:insert into t(field) values(v1),(v2),(v3)
2. sqlSession.commit();实际上并不是事务的commit，而只是执行sql
3. 2个事务绑定的是同一个connection。
4. 在一个mybatis的sqlSession 批量中操作两张表，则会生成两个prepareStatement，
5. 而prepareStatement对象在mybatis中有cache。
6. 回滚时回滚到savepoint

基于上面6点， 当第一个事务的第一个表执行是失败后（在第一个表的失败位置上设置一个savepoint，回滚时值回滚到这个savepoint，第二个preparestatement被缓存了）

# 问题总结

1. 本问题不设计到事务传播机制与隔离级别
2. 本例为一个错误使用范例，**即不能在一个mybatis的sqlSession批量中操作两张表**

<span style="color:blue">*注意：PreparedStatement确实适合执行相同sql的批处理，Statement适合执行不同sql的批处理*</span>

一些代码跟踪截图这里就不方便放出来请见谅。



