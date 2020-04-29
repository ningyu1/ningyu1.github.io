---
title : "Java对象复制类库性能对比"
description : "Java对象复制类库性能对比"
tags : [
	"Java",
	"对象拷贝"
]
date : "2019-03-22 16:03:21"
categories : [
    "Java"
]
---

# 背景

在开发中我们经常会用到对象之间的互相拷贝，`Java`中对象拷贝的类库也比较多，常见的有`Spring BeanUtils`，`Apache BeanUtils`，等并且在很多大厂公司对对象拷贝也有详尽的说明，避免大家踩坑。

# 功能对比

|耗时(毫秒)|1000次|10,000次|100,100次|
|:--|:--|:--|:--|
|`Apache BeanUtils`|298|983|4211|
|`Cglib BeanCopier`|89|120|203|
|`Spring BeanUtils`|92|160|524|

# 性能对比

| |Apache BeanUtils|Cglib BeanCopier|Spring BeanUtils|
|:--|:--|:--|:--|
|非public类|不支持|支持|支持|
|基本类型与装箱类型，int->Integer，Integer->int|支持，可以copy|不支持，不copy|不支持，不copy|
|int->long，long->int，int->Long，Integer->long|不支持|不支持|不支持|
|源对象相同属性无get方法|不支持 不copy|不支持 不copy|不支持 不copy|
|目标对象相同属性无get方法|支持|不支持|支持|
|目标对象相同属性无set方法|不copy，不报错|报错|不copy，不报错|
|源对象相同属性无set方法|支持|支持|支持|
|目标对象相同属性set方法返回非void|不设置，其他正常属性可以copy|不设置，导致其他属性都无法copy|支持，能够copy|
|目标对象多字段|支持|支持|支持|
|目标对象少字段|支持|支持|支持|

# 结论

从性能对比来看：

1. `cglib`的`BeanCopier`最好， `Spring BeanUtils`稍微差点，但也还可以，`Apache BeanUtils`性能最差
2. 从功能对比来看，`cglib` 在set方法返回非void时，会导致其他属性无法copy，目标没有set方法时，会报错，还存在并且有多项不支持的情况