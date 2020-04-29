---
title : "Mybatis PageHelper分页遇到的坑，莫名其妙的增加了limit ?,?"
description : "Mybatis PageHelper分页遇到的坑，莫名其妙的增加了limit ?,?"
tags : 
- Java
- Mybatis
- PageHelper
date : "2019-04-02 15:36:21"
categories : 
- Java
- Mybatis
---

# 背景

在使用Mybatis分页插件PageHelper的时候我相信或多或少都会遇到这样的问题，明明没有分页的语句执行后sql语句被自动添加了limit ？,?，看起来非常的莫名其妙，其实这个问题非常明确，就是Java基本功的问题，由于开发使用的是pagehelper.startPage方式，弄出这个问题就是对pagehelper的分页原理不理解而导致的。

首先我们先介绍一下Mybatis的分页用法。

# Mybatis分页用法

## RowBounds用法

显示的使用RowBounds参数，这种方法是最安全的，在经过Mybatis处理的时候会根据RowBounds参数来自动添加limit表达式，但是这种方法有个缺点，就是需要分页的方法都要增加RowBounds这个参数，其实也很正常，这也是最原始的用法，只是现在开发被惯叼了，又想少写代码又想使用最全的功能。


## PageHelper用法

使用pagehelper，这个是一个使用率最高的Mybatis分页插件，使用起来也比较方便，但是包装了很多高级的功能需要理解他的机制，要不然很容易写出bug，例如这次的问题，sql中明明没有使用分页，但是最后执行的sql语句中多了limit。

pagehelper的4.x以上的版本使用pageHelper.startPage方法来进行分页，这种方法是在需要执行的sql之前调用一次，例如：

```
PageHelper.startPage(1, 10);
list = countryMapper.selectIf(param1);
```

## PageHelper优缺点

优点：
1. 使用简单
2. 对sql无侵入

缺点：
1. 不是及其安全的方式（至少跟采用RowBounds参数进行分页的方式来比较）

## PageHelper分页原理

PageHelper采用ThreadLocal来进行分页标识设置，pagehelper保证的是当代码执行到Executor 方法时出现错误，它会在finally快中清理ThreadLocal中的分页标识，如果代码没有执行到Executor方法就出现异常，那就会造成ThreadLocal污染。
当我们执行`PageHelper.startPage(1, 10);`这一行的时候，其实是在当前线程的ThreadLocal中设置了分页的变量，当执行到`countryMapper.selectIf(param1);`的时候会通过Executor拦截，从ThreadLocal中获取分页标记，如果存在分页标记就在当前执行的sql语句中增加分页表达式，当Executor拦截执行的时候finally中会清理ThreadLocal中的分页变量。

# 问题分析

接下来让我们看一下出现的错误

```
2019-03-28 00:00:00.150 [DubboServerHandler-xx.xx.xx.xx:yyyy-thread-191] DEBUG org.apache.ibatis.logging.jdbc.BaseJdbcLogger.debug(BaseJdbcLogger.java:139) - ==>  Preparing: SELECT id, job...skipping...
### The error may involve xx.yy.zz.XXXXMapper.loadExpress-Inline
### The error occurred while setting parameters
### SQL: select     field as fieldName   from table where field= ?    order by id ASC limit 1 limit ?,?
### Cause: com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'limit 0,50' at line 5
; bad SQL grammar []; nested exception is com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'limit 0,50' at line 5, dubbo version: 2.5.3, current host: 10.24.232.204 #-# org.springframework.jdbc.BadSqlGrammarException:
### Error querying database.  Cause: com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'limit 0,50' at line 5
### The error may exist in URL [jar:file:/usr/local/dubbo/xxx/lib/xxx-yyy-1.0.0.jar!/sqlMap/express/XXXXMapper.xml]
### The error may involve xx.yy.zz.XXXXMapper.loadExpress-Inline
### The error occurred while setting parameters
### SQL: select     field as fieldName  from table where field= ?    order by id ASC limit 1 limit ?,?
### Cause: com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'limit 0,50' at line 5
; bad SQL grammar []; nested exception is com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'limit 0,50' at line 5
```

我们来看一下方法实现代码

```
@Override
public XXXVo loadExpress(param){
    XXXEntity param = new XXXEntity();
    param.setBusinessNo(businessNo);
    XXXEntity  entity = XXXMapper.loadExpress(param);
    //省略无关代码
}
```

我们看一下sqlmap

```
<select id="loadExpress" parameterType="xx.yy.zz.XXXEntity"
        resultType="xx.yy.zz.XXXEntity">
    select
        field as fieldName 
    from table 
        where business_no= #{businessNo}
        order by id ASC limit 1
</select>
```

这个方法是唯一入口，并且没有执行pagehelper.startPage，但是语句在执行的时候自动加了`limit 0,50`，这个分页的数据非常像是页面的列表查询设置的分页变量。

其实问题所在是执行线程被污染，因为我们都是使用线程池的，当前执行所用的线程是会被放回池子中被反复使用的，如果某个执行污染了线程那就会影响下一个执行的代码。

我们来举个例子，看如下代码：

```
public void method01() { //@1
    PageHelper.startPage(1, 10); //@5
    List<Country> list;
    if(param1.get() != null){ //@2
        list = countryMapper.selectIf(param1);
    } else {
        list = new ArrayList<Country>();
    }
}
 
public List<Country> method02() { //@3
    List<Country> list = countryMapper.selectNotPage(param1); //@4
    return list;
}
```

假设我们一个请求进来调用method01()方法，随后另外的请求进来调用的是method02()方法，假定我们的线程池数量是1，让两个请求使用同一个线程。
1. 请求从`@1`处进入
2. 执行到`@2`处发生了NullPointException异常
3. 随后的请求从`@3`处进入
4. 执行`@4`处时执行的sql会被自动添加limit ?,?。

## 错误原因

因为前一个请求执行`@5`处时设置了分页标识到ThreadLocal中，当执行到`@2`处时触发了异常，`@5`处设置的分页变量没有被消费和清理，线程被污染，因此另一个请求进来复用了这个线程，当执行到`@4`处时PageHelper拦截器从ThreadLocal中获取到分页变量并自动增加了`limit ?,?`语句。

# 解决方法

## 推荐使用的方式

在执行`PageHelper.startPage(1, 10);`之后紧跟着执行`Executor`，避免这两行之间出现错误，将我们上图举例中的代码修改一下如下：

```
public void method01() {
    List<Country> list;
    if(param1.get() != null){
        //两行紧挨着执行，避免出现异常
        PageHelper.startPage(1, 10);
        list = countryMapper.selectIf(param1);
    } else {
        list = new ArrayList<Country>();
    }
}
```

<span style="color:blue">*ps. 要保证两行紧挨着执行，并且在执行了PageHelper.startPage之后与countryMapper.selectIf之前保证不会出错误。*</span>

## 不推荐使用方式

使用finally快进行清理，如下图：

```
public void method01() {
    List<Country> list;
    if(param1.get() != null){
        //修改面太大，代码侵入太多
        try {
            PageHelper.startPage(1, 10);
            list = countryMapper.selectIf(param1);
        } finally {
            PageHelper.clearPage();
        }
    } else {
        list = new ArrayList<Country>();
    }
}
```

<span style="color:blue">*ps. 参考pagehelper的<a href="https://github.com/pagehelper/Mybatis-PageHelper/blob/master/wikis/en/HowToUse.md">安全使用指南</a>*</span>

# 总结

只有理解了pagehelper的分页机制之后才能别面写法带来的bug，我相信当我提到pagehelper采用ThreadLocal实现的分页标识传递时，应该有很多人已经明白了问题所在。任何通过ThreadLocal传递变量时都有可能出现线程污染的问题，尽量规避掉。

ThreadLocal传递变量是个非常好的方式，俗称为隐士传参，具有包装透明的效果，正因为这个特性更要注意安全清理的问题，需要全面思考代码执行过程中是否会出现错误，出现错误是否能友好的清理掉线程中透传的变量，如果处理不得当就会造成线程污染。
