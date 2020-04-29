---
toc : true
title : "New Version V1.2.0, Dubbo Plugin for Apache JMeter"
description : "New Version V1.2.0, Dubbo Plugin for Apache JMeter"
tags : [
	"jmeter",
	"dubbo",
	"test",
	"Dubbo可视化测试工具",
	"Jmeter对Dubbo接口进行可视化压力测试",
	"Dubbo Jmeter插件"
]
date : "2018-03-13 13:18:21"
categories : [
    "test"
]
menu : "main"
---


# 项目地址

jmeter-plugin-dubbo项目已经transfer到dubbo group下

[github: jmeter-plugin-dubbo](https://github.com/dubbo/jmeter-plugins-dubbo) 

[码云: jmeter-plugin-dubbo]( https://gitee.com/ningyu/jmeter-plugins-dubbo)

# V1.2.0

1. 使用gson进行json序列化、反序列化
2. 使用dubbo泛化调用方式重构反射调用方式
3. 支持复杂类型、支持泛型，例如："java.lang.List<ResourceVo>,Map<String,ResourceVo> map,List<Map<String, ResourceVo>> list"

本次版本主要对反射参数类型进行了增强，支持复杂类型、支持参数泛型，可以参考如下的参数对照表：

|Java类型|paramType|paramValue|
|:------|:--------|:---------|
|int|int|1|
|double|double|1.2|
|short|short|1|
|float|float|1.2|
|long|long|1|
|byte|byte|字节|
|boolean|boolean|true或false|
|char|char|A，如果字符过长取值为："STR".charAt(0)|
|java.lang.String|java.lang.String或String或string|字符串|
|java.lang.Integer|java.lang.Integer或Integer或integer|1|
|java.lang.Double|java.lang.Double或Double|1.2|
|java.lang.Short|java.lang.Short或Short|1|
|java.lang.Long|java.lang.Long或Long|1|
|java.lang.Float|java.lang.Float或Float|1.2|
|java.lang.Byte|java.lang.Byte或Byte|字节|
|java.lang.Boolean|java.lang.Boolean或Boolean|true或false|
|JavaBean|com.package.Bean|{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}|
|java.util.Map以及子类|java.util.Map以及子类|{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}|
|java.util.Map&#60;String,JavaBean> |java.util.Map|{"name":{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}}|
|java.util.HashMap&#60;Object,Object>|java.util.HashMap|{"name":{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}}|
|java.util.Collection以及子类|java.util.Collection以及子类|["a","b"]|
|java.util.List&#60;String>|java.util.List|["a","b"]|
|java.util.List&#60;JavaBean>|java.util.List|[{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}]|
|java.util.List&#60;Map&#60;Object, JavaBean>>|java.util.List|[{"name":{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}},{"name":{"service":"test1","url":"test-${__RandomString(5,12345,ids)}","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}}]|
|java.util.List&#60;Long>|java.util.List| [1,2,3]|
|java.util.ArrayList&#60;Object>|java.util.ArrayList|["ny",1,true]|