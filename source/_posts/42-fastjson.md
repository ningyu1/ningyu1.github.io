---
toc : true
title : "Fastjson反序列化java.lang.VerifyError错误"
description : "Fastjson反序列化java.lang.VerifyError错误"
tags : [
	"Fastjson"

]
date : "2017-12-15 15:42:36"
categories : [
    "java"
]
menu : "main"
---

# 现象

当反序列化目标对象属性超过32个时会报如下错误：

```
Exception in thread "main" java.lang.VerifyError: (class: com/alibaba/fastjson/parser/deserializer/FastjsonASMDeserializer_1_OmsMaterialStorageReconciliationEntity, method: deserialze signature: (Lcom/alibaba/fastjson/parser/DefaultJSONParser;Ljava/lang/reflect/Type;Ljava/lang/Object;I)Ljava/lang/Object;) Accessing value from uninitialized register 48
    at java.lang.Class.getDeclaredConstructors0(Native Method)
    at java.lang.Class.privateGetDeclaredConstructors(Class.java:2493)
    at java.lang.Class.getConstructor0(Class.java:2803)
    at java.lang.Class.getConstructor(Class.java:1718)
    at com.alibaba.fastjson.parser.deserializer.ASMDeserializerFactory.createJavaBeanDeserializer(ASMDeserializerFactory.java:82)
    at com.alibaba.fastjson.parser.ParserConfig.createJavaBeanDeserializer(ParserConfig.java:639)
    at com.alibaba.fastjson.parser.ParserConfig.getDeserializer(ParserConfig.java:491)
    at com.alibaba.fastjson.parser.ParserConfig.getDeserializer(ParserConfig.java:348)
    at com.alibaba.fastjson.parser.DefaultJSONParser.parseObject(DefaultJSONParser.java:639)
    at com.alibaba.fastjson.JSON.parseObject(JSON.java:350)
    at com.alibaba.fastjson.JSON.parseObject(JSON.java:254)
    at com.alibaba.fastjson.JSON.parseObject(JSON.java:467)
    at com.jiuyescm.uam.main.Main.main(Main.java:29)
```

查看我们使用的fastjson包版本：

```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.28</version>
</dependency>
```

查看官方issues是否有同样的问题

找到问题：[https://github.com/alibaba/fastjson/issues/1071](https://github.com/alibaba/fastjson/issues/1071)

是一个反序列化的bug，在1.2.29版本修复

![](/img/fastjson/1.png)

升级我们使用的fastjson版本验证是否修复问题

```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.29</version>
</dependency>
```

测试代码：

```
public static void main(String[] args) throws IOException {
    String a = "{\"region\":\"aaa\",\"weight\":null,\"outqty\":null,\"inVolume\":null,\"qtyMax\":null,\"creTime\":null,\"lastStock\":null,\"inHeight\":null,\"wallThickness\":null,\"id\":null,\"height\":null,\"length\":null,\"materialType\":null,\"inqty\":null,\"materialTypeName\":null,\"materialName\":null,\"supplierId\":null,\"status\":null,\"width\":null,\"barcode\":null,\"qtyMin\":null,\"crePersonId\":null,\"unit\":null,\"changeDate\":null,\"initStock\":null,\"materialNo\":null,\"crePerson\":null,\"inLength\":null,\"materialPrice\":null,\"volume\":null,\"inWidth\":null,\"warehouseNo\":null}";
    OmsMaterialStorageReconciliationEntity t2 = JSON.parseObject(a, OmsMaterialStorageReconciliationEntity.class);
    System.out.println(t2.getRegion());
}
```

OmsMaterialStorageReconciliationEntity 这个entity对象属性超过32个，运行测试结果：

```
aaa
```

运行结果符合预期，验证完毕

# 结论

* 升级fastjson包版本 -> 1.2.29
