---
toc : true
title : "使用downloadjs下载并且重命名文件名称引发的跨域问题"
description : "使用downloadjs下载并且重命名文件名称引发的跨域问题"
tags : [
	"js",
	"downloadjs",
	"cors"
]
date : "2018-08-02 14:50:00"
categories : [
    "js",
	"cors"
]
menu : "main"
---

我们有一部分静态资源放在fastdfs文件服务器上，并且文件名称是生成的随机数，直接浏览器下载是可以正常下载文件的，但是我们需要修改下载文件的名称，直接a标签href是无法修改下载文件名称的。

使用a标签的download属性又有浏览器兼容问题，而且download属性有一个弊端，只有点击右键另存为才会生效，直接点击是不生效的。


因此我们这里借助了一个组件[downloadjs](https://github.com/rndme/download)来进行文件下载，它可以修改下载文件的名称，并且也没有浏览器兼容问题，原理呢很简单那，使用ajax请求去下载文件，在发起请求时构造请求header来重命名下载文件名。

但是这里会存在一个问题？我们的fastdfs和应用程序是独立的两个域，因此存在跨域的问题，直接使用a标签的href是不存在跨域的问题，按关于这个跨域的问题我们如何解决？

先来看一下使用downloadjs下载fastdfs的文件时报出的跨域错误信息如下

```
Failed to load http://192.168.0.48:8079/group1/M00/03/35/wKgAMFtgB2SAFjibAAX3egrfUI8922.doc: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://localhost:8080' is therefore not allowed access.
```

本地使用是通过vue的proxyTable绕过跨域的问题，其实就是前端的proxy方式虚拟一个context然后pass转发，虽然这样可以解决目前的问题，但是我们在uat和prd环境又要增加相同的context path的映射，这不是我们想要的，我们想直接访问下载地址来进行下载，因此我们需要修改fastdfs的nginx模块配置。

跨域的配置这里就不多说了，其实就是添加一系列的Access-Control-Allow-X的header即可，不会的可以参考我以前的文章[跨域踩坑经验总结》](https://ningyu1.github.io/site/post/92-cors-ajax/)，唯一需要注意的是，当使用`Access-Control-Allow-Credentials=true`时`Access-Control-Allow-Origin`不允许使用`*` 必须使用具体的域名多个可以使用`,`分割。

修改后我们可以直接的请求地址下载文件即可。

