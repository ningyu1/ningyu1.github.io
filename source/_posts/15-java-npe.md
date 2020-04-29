---
toc : true
title : "NPE（java.lang.NullPointerException）防范"
description : "NPE（java.lang.NullPointerException）防范"
tags : [
    "NPE",
	"NullPointException"

]
date : "2017-08-26 16:01:36"
categories : [
    "Java"
]
menu : "main"
---


我们程序中NPE还是比较多的，下面介绍良好的编码规范防止NPE的发生

NPE（java.lang.NullPointerException）: 空指针异常



## 一、【推荐】防止 NPE，是程序员的基本修养，注意 NPE 产生的场景：

1） 返回类型为基本数据类型， return 包装数据类型的对象时，自动拆箱有可能产生 NPE。

反例： public int f() { return Integer 对象}， 如果为 null，自动解箱抛 NPE。

2） 数据库的查询结果可能为 null。

3） 集合里的元素即使 isNotEmpty，取出的数据元素也可能为 null。

4） 远程调用返回对象时，一律要求进行空指针判断，防止 NPE。

5） 对于 Session 中获取的数据，建议 NPE 检查，避免空指针。

6） 级联调用 obj.getA().getB().getC()； 一连串调用，易产生 NPE。

正例： 使用 JDK8 的 Optional 类来防止 NPE 问题。

ps.我们现在开发规范jdk版本jdk1.7.0_45，对于jdk8里面的optional可以了解学习，它是一种友好的解决方式。



## 二、【强制】当某一列的值全是 NULL 时， count(col)的返回结果为 0，但 sum(col)的返回结果为

NULL，因此使用 sum()时需注意 NPE 问题。

正例： 可以使用如下方式来避免 sum 的 NPE 问题： SELECT IF(ISNULL(SUM(g)),0,SUM(g))

FROM table;



## 三、【推荐】高度注意 Map 类集合 K/V 能不能存储 null 值的情况，如下表格：

|集合类|Key|Value|Super|说明|
|:----|:---|:---|:-----|:--|
|Hashtable|不允许为null|不允许为null|Dictionary|线程安全|
|ConcurrentHashMap|不允许为null|不允许为null|AbstractMap|分段锁技术|
|TreeMap|不允许为null|允许为null|AbstractMap|线程不安全|
|HashMap|允许为null|允许为null|	AbstractMap|线程不安全|

反例： 由于 HashMap 的干扰，很多人认为 ConcurrentHashMap 是可以置入 null 值，而事实上，

存储 null 值时会抛出 NPE 异常。



## 四、【推荐】方法的返回值可以为 null，不强制返回空集合，或者空对象等，必须添加注释充分

说明什么情况下会返回 null 值。调用方需要进行 null 判断防止 NPE 问题。

说明： 明确防止 NPE 是调用者的责任。即使被调用方法返回空集合或者空对象，对调用

者来说，也并非高枕无忧，必须考虑到远程调用失败、 序列化失败、 运行时异常等场景返回

null 的情况。



## 五、关于基本数据类型与包装数据类型的使用标准如下：

1） 【强制】 所有的 POJO 类属性必须使用包装数据类型。

2） 【强制】 RPC 方法的返回值和参数必须使用包装数据类型。

3） 【 推荐】 所有的局部变量使用基本数据类型。

说明： POJO 类属性没有初值是提醒使用者在需要使用时，必须自己显式地进行赋值，任何

NPE 问题，或者入库检查，都由使用者来保证。

正例： 数据库的查询结果可能是 null，因为自动拆箱，用基本数据类型接收有 NPE 风险。


<span style="color:blue">***以上内容摘自阿里巴巴Java开发手册v1.2.0.pdf***</span>