---
toc : true
title : "MybatisSql获取工具类SqlHelper使用说明"
description : "MybatisSql获取工具类SqlHelper使用说明"
tags : [
    "Mybatis",
	"Sqlhelper"

]
date : "2017-09-05 17:50:36"
categories : [
    "Mybatis"
]
menu : "main"
---

## 项目地址
[tsoft-common](https://github.com/ningyu1/tsoft-parent/tree/master/tsoft-common "tsoft-common")

[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0.html)

## 前言

有的时候我们想在代码中获取Mybatis方法的sql但是又不想去实际执行Mybatis的查询方法，可以使用该工具直接得到sql。

## Maven引入

```xml
<dependency>
  <groupId>cn.tsoft.framework</groupId>
  <artifactId>tsoft-common</artifactId>
  <version>1.0.0-SNAPSHOT</version>
</dependency>
```

## 目标
SqlHelper是获取Mybatis方法的sql工具包，支持mybatis mapper方式和sqlmap方式，支持参数：entity，map，array，list，这个工具不需要你实际去执行Mybatis的查询方法就能得到sql，方法主要分两大类，使用命名空间namespace调用或者使用Mapper接口方式调用。

## 测试方法

```java
String sql = null;
UserEntity entity = new UserEntity();
entity.setUserId(1L);
entity.setPassword("sdflkjsldjf");
entity.setPasswordExpire(new Date());
entity.setVersion(2L);
List<Long> list = new ArrayList<Long>();
list.add(1L);
list.add(2L);
Long[] ids = new Long[]{1L,2L};
//方式一
sql = SqlHelper.getMapperSql(userMapper, "mobileIsExists", 1L, "13800138000");
System.out.println("方式一：参数为：@Param："+sql);
sql = SqlHelper.getMapperSql(userMapper, "mobileIsExists");
System.out.println("方式一：参数为：无参："+sql);
sql = SqlHelper.getMapperSql(userMapper, "modifyPassword", entity);
System.out.println("方式一：参数为：entity"+sql);
sql = SqlHelper.getMapperSql(userMapper, "blockedArrays", ids);
System.out.println("方式一：参数为：arrays"+sql);
sql = SqlHelper.getMapperSql(userMapper, "blockedList", list);
System.out.println("方式一：参数为：list"+sql);
 
SqlSession sqlSession = mybatisSessionFactory.getObject().openSession();
//方式二
sql = SqlHelper.getMapperSql(sqlSession, "cn.tsoft.account.mapper.UserMapper.mobileIsExists", 1L, "13800138000");
System.out.println("方式二：参数为：@Param："+sql);
sql = SqlHelper.getMapperSql(sqlSession, "cn.tsoft.account.mapper.UserMapper.mobileIsExists");
System.out.println("方式二：参数为：无参："+sql);
sql = SqlHelper.getMapperSql(sqlSession, "cn.tsoft.account.mapper.UserMapper.modifyPassword", entity);
System.out.println("方式二：参数为：entity"+sql);
sql = SqlHelper.getMapperSql(sqlSession, "cn.tsoft.account.mapper.UserMapper.blockedArrays", ids);
System.out.println("方式二：参数为：arrays"+sql);
sql = SqlHelper.getMapperSql(sqlSession, "cn.tsoft.account.mapper.UserMapper.blockedList", list);
System.out.println("方式二：参数为：list"+sql);
 
//方式三
sql = SqlHelper.getMapperSql(sqlSession, UserMapper.class, "mobileIsExists", 1L, "13800138000");
System.out.println("方式三：参数为：@Param："+sql);
sql = SqlHelper.getMapperSql(sqlSession, UserMapper.class, "mobileIsExists");
System.out.println("方式三：参数为：无参："+sql);
sql = SqlHelper.getMapperSql(sqlSession, UserMapper.class, "modifyPassword", entity);
System.out.println("方式三：参数为：entity"+sql);
sql = SqlHelper.getMapperSql(sqlSession, UserMapper.class, "blockedArrays", ids);
System.out.println("方式三：参数为：arrays"+sql);
sql = SqlHelper.getMapperSql(sqlSession, UserMapper.class, "blockedList", list);
System.out.println("方式三：参数为：list"+sql);
```

## 日志输出

```log
方式一：参数为：@Param：
SELECT COUNT(t.`ID`) FROM t_user t 
WHERE t.`MOBILE` = '13800138000'
          
            AND t.`USER_ID` != '1'
方式一：参数为：无参：
SELECT COUNT(t.`ID`) FROM t_user t 
WHERE t.`MOBILE` = 'null'
方式一：参数为：entity：
UPDATE t_user t 
        SET 
        t.`PASSWORD` = 'sdflkjsldjf' , 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`PASSWORD_MODIFY_TIME` = CURRENT_TIMESTAMP , 
        t.`PASSWORD_EXPIRE` = 'Fri Aug 25 19:36:00 CST 2017' , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` = 1 
        AND t.`VERSION` = 2
方式一：参数为：arrays：
UPDATE t_user t
        SET 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` in
           
            1
         , 
            2
方式一：参数为：list：
UPDATE t_user t
        SET 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` in
           
            1
         , 
            2
方式二：参数为：@Param：
SELECT COUNT(t.`ID`) FROM t_user t 
        WHERE t.`MOBILE` = '13800138000'
          
            AND t.`USER_ID` != '1'
方式二：参数为：无参：
SELECT COUNT(t.`ID`) FROM t_user t 
        WHERE t.`MOBILE` = 'null'
方式二：参数为：entity：
UPDATE t_user t 
        SET 
        t.`PASSWORD` = 'sdflkjsldjf' , 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`PASSWORD_MODIFY_TIME` = CURRENT_TIMESTAMP , 
        t.`PASSWORD_EXPIRE` = 'Fri Aug 25 19:36:00 CST 2017' , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` = 1 
        AND t.`VERSION` = 2
方式二：参数为：arrays：
UPDATE t_user t
        SET 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` in
           
            1
         , 
            2
方式二：参数为：list：
UPDATE t_user t
        SET 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` in
           
            1
         , 
            2
方式三：参数为：@Param：
SELECT COUNT(t.`ID`) FROM t_user t 
        WHERE t.`MOBILE` = '13800138000'
          
            AND t.`USER_ID` != '1'
方式三：参数为：无参：
SELECT COUNT(t.`ID`) FROM t_user t 
        WHERE t.`MOBILE` = 'null'
方式三：参数为：entity：
UPDATE t_user t 
        SET 
        t.`PASSWORD` = 'sdflkjsldjf' , 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`PASSWORD_MODIFY_TIME` = CURRENT_TIMESTAMP , 
        t.`PASSWORD_EXPIRE` = 'Fri Aug 25 19:36:00 CST 2017' , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` = 1 
        AND t.`VERSION` = 2
方式三：参数为：arrays：
UPDATE t_user t
        SET 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` in
           
            1
         , 
            2
方式三：参数为：list：
UPDATE t_user t
        SET 
        t.`LAST_UPDATE_TIME` = CURRENT_TIMESTAMP , 
        t.`VERSION` = t.`VERSION` + 1 
        WHERE 
        t.`USER_ID` in
           
            1
         , 
            2
```
