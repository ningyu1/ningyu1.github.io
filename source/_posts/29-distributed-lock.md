---
toc : true
title : "分布式锁（Redis实现）使用说明"
description : "分布式锁（Redis实现）使用说明"
tags : [
    "Redis",
	"Lock",
	"Distributed"

]
date : "2017-09-27 16:43:36"
categories : [
    "Redis",
	"Lock",
	"Distributed"
]
menu : "main"
---

## 概述

[![GitHub release](https://img.shields.io/github/release/ningyu1/distributed-lock.svg?style=social&label=Release)](https://github.com/ningyu1/distributed-lock/releases)&nbsp;[![GitHub stars](https://img.shields.io/github/stars/ningyu1/distributed-lock.svg?style=social&label=Star)](https://github.com/ningyu1/distributed-lock/stargazers)&nbsp;[![GitHub forks](https://img.shields.io/github/forks/ningyu1/distributed-lock.svg?style=social&label=Fork)](https://github.com/ningyu1/distributed-lock/fork)&nbsp;[![GitHub watchers](https://img.shields.io/github/watchers/ningyu1/distributed-lock.svg?style=social&label=Watch)](https://github.com/ningyu1/distributed-lock/watchers)

## 项目地址
[distributed-lock](https://github.com/ningyu1/distributed-lock "项目地址") 

[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0.html)

分布式锁，默认是redis实现，可扩展接口增加zk、等其他实现,这个分布式锁采用redis实现，根据CAP理论保证了可用性、分区容错性、和最终一致性。

## 实现的分布式锁特性

1. 这把锁是非阻塞锁，可以根据超时时间和重试频率来定义重试次数
2. 这把锁支持失效时间，极端情况下解锁失败，到达时间之后锁会自动删除
3. 这把锁是非重入锁，一个线程获得锁之后，在释放锁之前，其他线程无法再次获得锁，只能根据获取锁超时时间和重试策略进行多次尝试获取锁。
4. 因为这把锁是非阻塞的，所以性能很好，支持高并发
5. 使用方无需手动获取锁和释放锁，锁的控制完全由框架控制操作，避免使用方由于没有释放锁或释放锁失败导致死锁的问题

## 实现的分布式锁缺点

1. 通过超时时间来控制锁的失效时间其实并不完美，但是根据性能和CAP理论有做取舍
2. 这把锁不支持阻塞，因为要达到高的性能阻塞的特性是要牺牲

## 使用步骤

### Maven中引入

```
<dependency>
    <groupId>cn.tsoft.framework</groupId>
    <artifactId>distributed-lock</artifactId>
    <version>1.1.0-SNAPSHOT</version>
</dependency>
```

### spring中引入配置

```
<import resource="classpath:spring-lock.xml" />
```

### 使用到了RedisClient

具体可以查看[《RedisCliet使用说明》](https://ningyu1.github.io/site/post/22-redis-client/)

```
<aop:aspectj-autoproxy />
<context:component-scan base-package="cn.tsoft.framework" />
<context:property-placeholder location="classpath:redis.properties"/>
<import resource="classpath:spring-redis.xml" />
```

### 代码中使用

```
import cn.tsoft.framework.lock.Lock;
import  cn.tsoft.framework.lock.LockCallBack;
import  cn.tsoft.framework.lock.DefaultLockCallBack;
 
@Autowired
Lock lock;

//方法一
T t = lock.lock("Test_key_2",20,60,new LockCallBack<T>(){
    public T handleObtainLock(){
        dosomething();
    }
    public T handleNotObtainLock() throws LockCantObtainException{
        return T;//throw new LockCantObtainException();
    }
    public T handleException(LockInsideExecutedException e) throws LockInsideExecutedException{
        return T;//throw new e;
    }
});

//方法二
T t = lock.lock("Test_key_2",LockRetryFrequncy.VERY_QUICK,20,60,new DefaultLockCallBack<T>(T,T){
    public T handleObtainLock(){
        dosomething();
    }
});
```

### 锁重试策略说明

```
/**
 * 锁重试获取频率策略
 * 
 * @author ningyu
 *
 */
LockRetryFrequncy.VERY_QUICK;  //非常快
LockRetryFrequncy.QUICK;       //快
LockRetryFrequncy.NORMAL;      //中
LockRetryFrequncy.SLOW;        //慢
LockRetryFrequncy.VERYSLOW;    //很慢
//例如：
//以获取锁的超时时间为：1秒来计算
//VERY_QUICK的重试次数为：100次
//QUICK的重试次数为：20次
//NORMAL的重试次数为：10次
//SLOW的重试次数为：2次
//QUICK的重试次数为：1次
//这个重试策略根据自身业务来选择合适的重试策略
```

### Example

#### 第一种用法

```
//锁名称：Test_key_2
//获取锁超时时间：20秒
//锁最大过期时间：60秒
//内部执行回调，包含（1.获取到锁回调，2.没有获取到锁回调，3.获取到锁内部执行业务代码报错）
//默认策略：NORMAL
lock.lock("Test_key_2",20,60,new LockCallBack<String>() {
   @Override
   public String handleException(LockInsideExecutedException e) throws LockInsideExecutedException {
       logger.error("获取到锁，内部执行报错");
       return "Exception";         
   }
 
   @Override
   public String handleNotObtainLock() throws LockCantObtainException {
          logger.error("没有获取到锁");
       return "NotObtainLock";
   }
 
   @Override
   public String handleObtainLock() {
       logger.info("获取到锁");
       dosomething();
       return "ok";
   }
);
```

#### 第二种用法

```
//锁名称：Test_key_2
//获取锁超时时间：20秒
//锁最大过期时间：60秒
//内部执行回调，使用默认回调实现，只需要实现获取到锁后需要执行的方法，当遇到没有获取锁和获取锁内部执行错误时会返回构造函数中设置的值（支持泛型）
//默认策略：NORMAL
lock.lock("Test_key_2",20,60,new DefaultLockCallBack<String>("NotObtainLock", "Exception") {
   @Override
   public String handleObtainLock() {
       logger.info("获取到锁");
       dosomething();
       return "ok";
   }
);
```

#### 第三种用法

```
//锁名称：Test_key_2
//锁重试获取频率：VERY_QUICK 非常快
//获取锁超时时间：20秒
//锁最大过期时间：60秒
//内部执行回调，包含（1.获取到锁回调，2.没有获取到锁回调，3.获取到锁内部执行业务代码报错）
lock.lock("Test_key_2",LockRetryFrequncy.VERY_QUICK,20,60,new LockCallBack<String>() {
   @Override
   public String handleException(LockInsideExecutedException e) throws LockInsideExecutedException {
       logger.error("获取到锁，内部执行报错");
       return "Exception";         
   }
 
   @Override
   public String handleNotObtainLock() throws LockCantObtainException {
          logger.error("没有获取到锁");
       return "NotObtainLock";
   }
 
   @Override
   public String handleObtainLock() {
       logger.info("获取到锁");
       dosomething();
       return "ok";
   }
);
```

#### 第四种用法

```
//锁名称：Test_key_2
//锁重试获取频率：VERY_QUICK 非常快
//获取锁超时时间：20秒
//锁最大过期时间：60秒
//内部执行回调，使用默认回调实现，只需要实现获取到锁后需要执行的方法，当遇到没有获取锁和获取锁内部执行错误时会返回构造函数中设置的值（支持泛型）
lock.lock("Test_key_2",LockRetryFrequncy.VERY_QUICK,20,60,new DefaultLockCallBack<String>("NotObtainLock", "Exception") {
   @Override
   public String handleObtainLock() {
       logger.info("获取到锁");
       dosomething();
       return "ok";
   }
);
```

### 注意事项

1. 获取锁的超时时间和重试策略直接影响获取锁重试的次数，根据业务场景来定义适合的重试获取锁的频次，避免线程阻塞。
2. 场景：
	1. 快速响应给客户端的场景，超时时间尽量短，超时时间 < 锁后执行时间，例如：秒杀、抢购
	2. 可以容忍响应速度的场景，锁后执行时间*2 > 超时时间 >=锁后执行时间
3. 根据业务场景来定义锁的最大过期时间，理论上业务执行越慢过期时间越大，因为是并发锁，为了杜绝因为获得锁而没有释放造成的问题
4. 建议 锁后执行时间*1.5 > 锁超时时间 > 锁后执行时间，避免并发问题
5. 获取锁后执行的代码块一定是小而快的，就像事务块使用原则一样，禁止重而长的逻辑包在里面造成其他线程获取锁失败率过高，如果逻辑很复杂需要分析那一块需要支持并发就把需要并发的代码包在里面。

