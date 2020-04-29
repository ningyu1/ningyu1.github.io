---
toc : true
title : "MySql Lock wait timeout exceeded该如何处理？"
description : "MySql Lock wait timeout exceeded该如何处理？"
tags : [
	"mysql",
	"Lock wait timeout exceeded"
]
date : "2018-04-08 18:02:00"
categories : [
    "mysql"
]
menu : "main"
---

这个问题我相信大家对它并不陌生，但是有很多人对它产生的原因以及处理吃的不是特别透，很多情况都是交给DBA去定位和处理问题，接下来我们就针对这个问题来展开讨论。

Mysql造成锁的情况有很多，下面我们就列举一些情况：

1. 执行DML操作没有commit，再执行删除操作就会锁表。
2. 在同一事务内先后对同一条数据进行插入和更新操作。
3. 表索引设计不当，导致数据库出现死锁。
4. 长事物，阻塞DDL，继而阻塞所有同表的后续操作。

但是要区分的是`Lock wait timeout exceeded`与`Dead Lock`是不一样。

* `Lock wait timeout exceeded`：后提交的事务等待前面处理的事务释放锁，但是在等待的时候超过了mysql的锁等待时间，就会引发这个异常。
* `Dead Lock`：两个事务互相等待对方释放相同资源的锁，从而造成的死循环，就会引发这个异常。

还有一个要注意的是`innodb_lock_wait_timeout`与`lock_wait_timeout`也是不一样的。

* `innodb_lock_wait_timeout`：innodb的dml操作的行级锁的等待时间 
* `lock_wait_timeout`：数据结构ddl操作的锁的等待时间

如何查看innodb_lock_wait_timeout的具体值？

```
SHOW VARIABLES LIKE 'innodb_lock_wait_timeout'
```

如何修改innode lock wait timeout的值？

参数修改的范围有Session和Global，并且支持动态修改，可以有两种方法修改：

方法一：

通过下面语句修改

```
set innodb_lock_wait_timeout=100;
set global innodb_lock_wait_timeout=100;
```

<span style="color:red">*ps. 注意global的修改对当前线程是不生效的，只有建立新的连接才生效。*</span>

方法二：

修改参数文件`/etc/my.cnf`
`innodb_lock_wait_timeout = 50`

<span style="color:red">*ps. `innodb_lock_wait_timeout`指的是事务等待获取资源等待的最长时间，超过这个时间还未分配到资源则会返回应用失败； 当锁等待超过设置时间的时候，就会报如下的错误；`ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction`。其参数的时间单位是秒，最小可设置为1s(一般不会设置得这么小)，最大可设置1073741824秒，默认安装时这个值是50s(默认参数设置)。*</span>


下面介绍在遇到这类问题该如何处理

# 问题现象

* 数据更新或新增后数据经常自动回滚。
* 表操作总报 `Lock wait timeout exceeded` 并长时间无反应

# 解决方法

* 应急方法：`show full processlist;` `kill`掉出现问题的进程。 <span style="color:blue">*ps.有的时候通过processlist是看不出哪里有锁等待的，当两个事务都在commit阶段是无法体现在processlist上*</span>
* 根治方法：`select * from innodb_trx;`查看有是哪些事务占据了表资源。 <span style="color:blue">*ps.通过这个办法就需要对innodb有一些了解才好处理*</span>

<span style="color:blue">说起来很简单找到它杀掉它就搞定了，但是实际上并没有想象的这么简单，当问题出现要分析问题的原因，通过原因定位业务代码可能某些地方实现的有问题，从而来避免今后遇到同样的问题。</span>


# innodb_*表的解释

`Mysql`的`InnoDB`存储引擎是支持事务的，事务开启后没有被主动`Commit`。导致该资源被长期占用，其他事务在抢占该资源时，因上一个事务的锁而导致抢占失败！因此出现 `Lock wait timeout exceeded`

下面几张表是innodb的事务和锁的信息表，理解这些表就能很好的定位问题。

`innodb_trx` ## 当前运行的所有事务
`innodb_locks` ## 当前出现的锁
`innodb_lock_waits` ## 锁等待的对应关系

下面对 `innodb_trx` 表的每个字段进行解释：

```
trx_id：事务ID。
trx_state：事务状态，有以下几种状态：RUNNING、LOCK WAIT、ROLLING BACK 和 COMMITTING。
trx_started：事务开始时间。
trx_requested_lock_id：事务当前正在等待锁的标识，可以和 INNODB_LOCKS 表 JOIN 以得到更多详细信息。
trx_wait_started：事务开始等待的时间。
trx_weight：事务的权重。
trx_mysql_thread_id：事务线程 ID，可以和 PROCESSLIST 表 JOIN。
trx_query：事务正在执行的 SQL 语句。
trx_operation_state：事务当前操作状态。
trx_tables_in_use：当前事务执行的 SQL 中使用的表的个数。
trx_tables_locked：当前执行 SQL 的行锁数量。
trx_lock_structs：事务保留的锁数量。
trx_lock_memory_bytes：事务锁住的内存大小，单位为 BYTES。
trx_rows_locked：事务锁住的记录数。包含标记为 DELETED，并且已经保存到磁盘但对事务不可见的行。
trx_rows_modified：事务更改的行数。
trx_concurrency_tickets：事务并发票数。
trx_isolation_level：当前事务的隔离级别。
trx_unique_checks：是否打开唯一性检查的标识。
trx_foreign_key_checks：是否打开外键检查的标识。
trx_last_foreign_key_error：最后一次的外键错误信息。
trx_adaptive_hash_latched：自适应散列索引是否被当前事务锁住的标识。
trx_adaptive_hash_timeout：是否立刻放弃为自适应散列索引搜索 LATCH 的标识。
```

下面对 `innodb_locks` 表的每个字段进行解释：

```
lock_id：锁 ID。
lock_trx_id：拥有锁的事务 ID。可以和 INNODB_TRX 表 JOIN 得到事务的详细信息。
lock_mode：锁的模式。有如下锁类型：行级锁包括：S、X、IS、IX，分别代表：共享锁、排它锁、意向共享锁、意向排它锁。表级锁包括：S_GAP、X_GAP、IS_GAP、IX_GAP 和 AUTO_INC，分别代表共享间隙锁、排它间隙锁、意向共享间隙锁、意向排它间隙锁和自动递增锁。
lock_type：锁的类型。RECORD 代表行级锁，TABLE 代表表级锁。
lock_table：被锁定的或者包含锁定记录的表的名称。
lock_index：当 LOCK_TYPE=’RECORD’ 时，表示索引的名称；否则为 NULL。
lock_space：当 LOCK_TYPE=’RECORD’ 时，表示锁定行的表空间 ID；否则为 NULL。
lock_page：当 LOCK_TYPE=’RECORD’ 时，表示锁定行的页号；否则为 NULL。
lock_rec：当 LOCK_TYPE=’RECORD’ 时，表示一堆页面中锁定行的数量，亦即被锁定的记录号；否则为 NULL。
lock_data：当 LOCK_TYPE=’RECORD’ 时，表示锁定行的主键；否则为NULL。
```

下面对 innodb_lock_waits 表的每个字段进行解释：

```
requesting_trx_id：请求事务的 ID。
requested_lock_id：事务所等待的锁定的 ID。可以和 INNODB_LOCKS 表 JOIN。
blocking_trx_id：阻塞事务的 ID。
blocking_lock_id：某一事务的锁的 ID，该事务阻塞了另一事务的运行。可以和 INNODB_LOCKS 表 JOIN。
```

# 锁等待的处理步骤

* 直接查看 innodb_lock_waits 表

```
SELECT * FROM innodb_lock_waits;
```

* innodb_locks 表和 innodb_lock_waits 表结合：

```
SELECT * FROM innodb_locks WHERE lock_trx_id IN (SELECT blocking_trx_id FROM innodb_lock_waits);
```

* innodb_locks 表 JOIN innodb_lock_waits 表:

```
SELECT innodb_locks.* FROM innodb_locks JOIN innodb_lock_waits ON (innodb_locks.lock_trx_id = innodb_lock_waits.blocking_trx_id);
```

* 查询 innodb_trx 表:

```
SELECT trx_id, trx_requested_lock_id, trx_mysql_thread_id, trx_query FROM innodb_trx WHERE trx_state = 'LOCK WAIT';
```

* trx_mysql_thread_id 即kill掉事务线程 ID

```
SHOW ENGINE INNODB STATUS ;
SHOW PROCESSLIST ;
```

从上述方法中得到了相关信息，我们可以得到发生锁等待的线程 ID，然后将其 KILL 掉。
KILL 掉发生锁等待的线程。

```
kill ID;
```




