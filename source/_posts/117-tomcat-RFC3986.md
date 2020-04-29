---
title : "Tomcat对[RFC 3986]规范的支持，导致一些特殊请求报错"
description : "Tomcat对[RFC 3986]规范的支持，导致一些特殊请求报错"
tags : 
- Tomcat
- RFC3986
date : "2019-06-26 17:46:21"
categories : 
- Tomcat
- RFC3986
---

# 背景

​	Tomcat在升级版本时遇到的一些问题，在升级tomcat版本后发现原有的功能莫名其妙的出现了错误，我们接下来看一下具体的问题以及分析一下具体的原因



# 问题分析

我们来具体看一下报错的请求报文

```java
http://localhost:8080/xx-rest/v1/report/salesOrder?
salesStatusList[]=&orderStatus=&salesTypeList[]=&itIsClose=&salesNo=&warehouseNo=&orderNo=&referenceNo=
&skuName=&skuBarcode=&shopNoList[]=&creTimeBeg=2019-06-21+00:00:00&creTimeEnd=2019-06-21+23:59:59
&platformOrderTimeBeg=&platformOrderTimeEnd=&endFinishTimeBeg=&endFinishTimeEnd=
&page=1&pageSize=50&customerNo=&__preventCache=1561084397458
```



调用后返回的是400的错误，并且进行了测试，当请求参数中存在[]时就会发生错误，去掉后可正常访问

我们查看到后台的错误具体如下：



```
2019/6/21 上午11:48:052019-06-21 11:48:05.590 [http-apr-8080-exec-3] INFO com.xxx.doFilter(CORSFilter.java:75) - CORS filter >>>>>> Because host:xxx.domain.com and origin:https://xxx.domain.com so Access-Control-Allow-Origin:https://xxx.domain.com
2019/6/21 上午11:48:05Jun 21, 2019 11:48:05 AM org.apache.coyote.http11.AbstractHttp11Processor process
2019/6/21 上午11:48:05INFO: Error parsing HTTP request header
2019/6/21 上午11:48:05 Note: further occurrences of HTTP header parsing errors will be logged at DEBUG level.
2019/6/21 上午11:48:05java.lang.IllegalArgumentException: Invalid character found in the request target. The valid characters are defined in RFC 7230 and RFC 3986
2019/6/21 上午11:48:05    at org.apache.coyote.http11.InternalAprInputBuffer.parseRequestLine(InternalAprInputBuffer.java:240)
2019/6/21 上午11:48:05    at org.apache.coyote.http11.AbstractHttp11Processor.process(AbstractHttp11Processor.java:1052)
2019/6/21 上午11:48:05    at org.apache.coyote.AbstractProtocol$AbstractConnectionHandler.process(AbstractProtocol.java:637)
2019/6/21 上午11:48:05    at org.apache.tomcat.util.net.AprEndpoint$SocketWithOptionsProcessor.run(AprEndpoint.java:2492)
2019/6/21 上午11:48:05    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
2019/6/21 上午11:48:05    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
2019/6/21 上午11:48:05    at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61)
2019/6/21 上午11:48:05    at java.lang.Thread.run(Thread.java:748)
```



非法参数：`Invalid character found in the request target. The valid characters are defined in RFC 7230 and RFC 3986`

意思说的是请求中包含了无效的字符，具体去看RFC 7230 and RFC 3986规范中的字符定义。

这个问题很纳闷！因为以前是没有遇到过的，于是先去看tomcat对RFC 7230 and RFC 3986规范的支持情况。



<span style="color:red">**Tomcat从 7.0.73, 8.0.39, 8.5.7 版本后添加了对Url的限制，遵循的就是RFC 7230 and RFC 3986规范。那我们就先搞清楚规范中描述的是什么。**</span>



## [RFC 3986]



[<https://www.ietf.org/rfc/rfc3986.txt>](<https://www.ietf.org/rfc/rfc3986.txt>)

我们只需关注规范中字符定义这块，我截图的地方

![](/img/rfc3986/1.png)

![](/img/rfc3986/2.png)



意思说的是规范中定义url中只允许包含英文字母(a-zA-Z)、数字(0-9)、-_.~四个特殊字符，保留字符用作特定领域分隔符，如果url中有用到需要进行转义

保留的字符有：` ! * ’ ( ) ; : @ & = + $ , / ? # [ ] `

 我们知道了RFC3986规范中的定义和tomcat支持规范的版本后问题就很明了了，我们来看一下我们使用的tomcat版本具体是多少，经过查看具体如下：


| 环境 | 版本 |
| -----| -----|
| UAT | apache-tomcat-7.0.67 |
| PRD | apache-tomcat-7.0.67 |
| dev、qa jdk7 | 使用的镜像是：tomcat:7，具体的tomcat版本是： Apache Tomcat/7.0.70 |
| dev、qa jdk8 | 使用的镜像是：tomcat:7-jre8，具体的tomcat版本是：Apache Tomcat/7.0.88|

问题就出在这里，我们使用的tomcat版本刚好是遵循RFC3986规范的tomcat版本。



# 解决办法 

知道了原因之后，具体的解决办法就比较明确了，大概有以下几种：

1. 对请求编码解码。 encodeURI，decodeURI，但是有的时候参数名中出现保留字符是比较麻烦的，需要对参数名进行转义，后台再解析参数时需要先对参数名解码后再通过参数名获取具体参数值
2. tomcat降版本到7.0.73以下，这个是比较好操作的