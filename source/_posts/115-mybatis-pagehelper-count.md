---
title : "PageHelper生成Count语句逻辑分析"
description : "PageHelper生成Count语句逻辑分析"
tags : 
- Java
- Mybatis
- PageHelper
date : "2019-04-22 19:24:21"
categories : 
- Java
- Mybatis
---

# 背景

在使用Mybatis分页插件时经常会遇到Mybatis生成的count语句效率很低，今天我们就看一下Mybatis中的countsql的生成逻辑是什么，为何会生成低效的countsql，怎么写sql可以避免低效countsql。



# 源码分析

`com.github.pagehelper.parser.CountSqlParser`



```java
/**
 * 将sql转换为count查询
 *
 * @param select
 */
public void sqlToCount(Select select) {
    SelectBody selectBody = select.getSelectBody();
    // 是否能简化count查询
    if (selectBody instanceof PlainSelect && isSimpleCount((PlainSelect) selectBody)) {
        ((PlainSelect) selectBody).setSelectItems(COUNT_ITEM);
    } else {
        PlainSelect plainSelect = new PlainSelect();
        SubSelect subSelect = new SubSelect();
        subSelect.setSelectBody(selectBody);
        subSelect.setAlias(TABLE_ALIAS);
        plainSelect.setFromItem(subSelect);
        plainSelect.setSelectItems(COUNT_ITEM);
        select.setSelectBody(plainSelect);
    }
}
 
/**
 * 是否可以用简单的count查询方式
 *
 * @param select
 * @return
 */
public boolean isSimpleCount(PlainSelect select) {
    //包含group by的时候不可以
    if (select.getGroupByColumnReferences() != null) {
        return false;
    }
    //包含distinct的时候不可以
    if (select.getDistinct() != null) {
        return false;
    }
    for (SelectItem item : select.getSelectItems()) {
        //select列中包含参数的时候不可以，否则会引起参数个数错误
        if (item.toString().contains("?")) {
            return false;
        }
        //如果查询列中包含函数，也不可以，函数可能会聚合列
        if (item instanceof SelectExpressionItem) {
            if (((SelectExpressionItem) item).getExpression() instanceof Function) {
                return false;
            }
        }
    }
    return true;
}

```

# 总结

看代码比较清晰明了，话不多说，总结如下：

1. sql包含group by的时候，会生成带子查询的低效countsql
2. sql包含distinct的时候，会生成带子查询的低效countsql
3. sql的列中包含参数的时候，会生成带子查询的低效countsql
4. sql的列中包含函数的时候，会生成带子查询的低效countsql

[pagehelper官方最新版](https://github.com/pagehelper/Mybatis-PageHelper/releases)更新到了：5.1.6

5.1.5版本有一个优化是对函数进行区分，如果是聚合函数生成带子查询的countsql，如果非聚合函数生成简单的countsql。

具体可以查看：[V5.1.5 changelog](https://github.com/pagehelper/Mybatis-PageHelper/releases)

![](/img/mybatis-pagehelper-count/1.png)

看了一下4.2.1 —— 5.1.6之间的版本，除了5.1.5支持了函数区分的支持以外，其他版本没有countsql生成相关的优化，所以sql中包含group by、distinct、列中包含参数，聚合函数会生成低效的countsql。