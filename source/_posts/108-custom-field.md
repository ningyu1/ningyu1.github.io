---
toc : true
title : "谈一谈自定义字段实现的几种方式"
description : "谈一谈自定义字段实现的几种方式"
tags : [
	"custom-field"
]
date : "2019-01-03 15:50:21"
categories : [
    "custom-field"
]
menu : "main"
---

我们经常会遇到项目中很多对表单进行自定义，比如说saas应用针对租户自定义表单字段名称，自定义列表名称。
还有更高级自定义，比如说自定义的模块，表单、字段、字段类型、流程等自定义。

提供自定义也是一个系统扩展性的体现，自定义功能的强大自然能适应更多的用户场景。

接下来我们就看看自定义的实现方案通常都有哪些方式。

常见的自定义字段的实现方式分为三种由简到繁，扩展性、复杂性也是逐渐增强的，每个方式各有优劣解决的场景也有所不同，具体往下看。

# 列式存储自定义字段（扩展字段 ext field）

模型如下：

|ID|Name|Ext1(性别)|Ext2(地区)|Ext3(QQ)|Ext4(WECHAT)|
|:--|:--|:--|:--|:--|:--|
|1|韩梅梅|女|Shanghai|10000| |
|2|李磊|男|Beijing| |abc001|

优点：

1. 实现成本最低
2. 可以直接表连接进行检索

缺点：

1. 扩展能力一般，有上限
2. 浪费资源，比如说有20个扩展字段，一行只用到2个，其余的18个都要存储null来浪费空间。
3. 能解决的场景比较有限。

# EAV模型 Entity-Attribute-Value（实体、属性、值）

对象属性存储在一个有三列的表中：实体，属性和值（entity，attribute，value)。实体（entiry）表示所描述的数据项，例如一个产品或汽车。属性（attribute）表示描述实体的数据，例如一个产品将有价格，重量和许多其他属性。值（value）是属性的值，例如产品可能有一个9.99英镑的价格属性。此外值可以基于数据类型进行分割，所以可将EAV表分为字符串、整数、日期和长文本（long text）表。依据数据类型分割是为了支持索引,使得数据库执行可能的类型检查验证。

EAV表模型带来了数据的灵活性，是的增加对象的属性不需要用增加数据库的字段，有很高的灵活性。但是EAV表也有较大的性能问题。通常，EAV表带来的一个问题是当查找多个字段时，需要进行关联查询join,这样的查询效率比较低。为了提高查询效率，我们可以对商品属性表进行矩阵转积处理(pivoting)。

一种方式是在代码中读出后存入cache中,当修改attributes表后触发更新cache或用cron定期更新;另一种方法是将关联信息组成一张大的临时表，数据的更新可以用数据库的触发器触发更新。由于大量数据在代码中进行处理会带来了DB的额外IO和服务器性能问题。当使用EAV表模型时，InnoDB比MYISAM的性能要好不少。

ps. 我们常用的行模型（纵向）存储就是EAV模型实现的一种方式。

模型如下：

人员表（Entity）

|ID|Name|
|:--|:--|
|1|韩梅梅|
|2|李磊|

扩展映射（Entities）

|Entity|Attribute|Value|
|:--|:--|:--|
|1	|sex（性别）	|女|
|2	|sex（性别）	|男|
|1	|region（地区）	|Shanghai|
|2	|region（地区）	|Beijing|
|1	|QQ	|10000|
|2	|WECHAT	|abc001|

优点：

1. 扩展能力较强
2. 理论上无上限
3. 可以支持几乎所有的自定义字段的需求

缺点：

1. 关联查询效率低下
2. 需要维护自定义字段与值的关系表

# Json格式存储自定义字段

json格式非常丰富，在描述自定义字段的这方面比较适合，可以把一行多列的数据压缩到一个json text内，也比较节省空间，json格式可以无限扩展，还可支持多个自定义字段有不同的格式。

模型如下：

|ID|Name|Content|
|:--|:--|:--|
|1|韩梅梅|{"sex":"女","region":"Shanghai","QQ":"10000"}|
|2|李磊|{"sex":"女","region":"Beijing","WECHAT":"abc001"}|

ps. 支持以上的两种不同的自定义格式并存

![](/img/custom-field/1.png)

优点：

1. 扩展能力强
2. 理论上无上限
3. 可以支持几乎所有的自定义字段的需求
4. 无需维护自定义字段与值关系

缺点：

1. 数据库需要支持json type，不建议使用text类型
2. 不支持关联查询（mongodb除外）
3. 自定义字段检索需要通过其他方式，例如搜索引擎。（mongodb除外）

## 数据库对Json格式支持情况

数据库对Json类型的支持：

1. Mysq5.7（[CRUD参考](http://www.lnmp.cn/mysql-57-new-features-json.html)）
2. PostgreSQL（[CRUD参考](https://www.enterprisedb.com/blog/crud-json-postgresql)，[json与jsonb区别](https://blog.csdn.net/qwdafedv/article/details/68066802)）
3. MongoDB（[CRUD参考](https://docs.mongodb.com/manual/crud/)）

数据库对json类型的检索支持：

1. Mysql5.7： 支持索引：通过虚拟列的功能可以对JSON中部分的数据进行索引。（相比PG和MongoDB弱一些，通过json_extract()函数做一些简单查询）
2. PostgreSQL：支持检索，可以复杂查询
3. MongoDB：支持检索，可以复杂查询，支持map reduce

ORM框架对Json类型的支持：

1. Mybatis支持json格式字段映射到POJO，方便json格式的bean与数据库映射。
2. Hibernate支持json格式字段映射到POJO，方便json格式的bean与数据库映射。

Mysql5.7.x json操作官方文档：

1. [json-creation-functions](https://dev.mysql.com/doc/refman/5.7/en/json-creation-functions.html)
2. [json-search-functions](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html)
3. [json-modification-functions](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html)

Mysql5.7.x 注意事项：

1. JSON_UNQUOTE 、->、->> 之间的区别
	* 下面三个表达式返回相同的值
		* JSON_UNQUOTE( JSON_EXTRACT(column, path) )
		* JSON_UNQUOTE(column -> path) 
		* column->>path
2. JSON_CONTAINS_PATH 参数说明
	* 第二个参数为'one'或'all'的区别
		* ‘one’：至少存在一个路径返回1，反之返回0
		* ‘all’：全部路径存在返回1，反之返回0
3. JSON_CONTAINS 参数说明
	* 第二个参数是不接受整数的，无论 json 元素是整型还是字符串，否则会出现这个错误
4. 5.7.x不同版本支持的程度：
	* MySQL 5.7.13
		* 支持操作符  ->> 
	* MySQL 5.7.9 
		* 支持操作符 -> （JSON_EXTRACT()函数别名）
		* 重命名函数JSON_APPEND()为JSON_ARRAY_APPEND()，函数作用：将值追加到JSON文档中指定数组的末尾并返回结果，未来会删除'JSON_APPEND()'
	* MySQL 5.7.22
		* 支持JSON_ARRAYAGG()返回json数组形式结果集，JSON_OBJECTAGG()返回kson对象形式结果集
		* 添加JSON_MERGE_PATCH()，作用：合并结果（相同path）
		* 添加JSON_MERGE_PRESERVE()，作用：合并数据（不同path）
		* 弃用JSON_MERGE()，使用JSON_MERGE_PRESERVE() / JSON_MERGE_PATCH()，未来会删除'JSON_MERGE()' 

实现方式不局限于上面说到的方式，有更好的方式欢迎留言进行沟通。