---
toc : true
title : "跨域踩坑经验总结（内涵：跨域知识科普）"
description : "跨域踩坑经验总结（内涵：跨域知识科普）"
tags : [
	"cors",
	"xhr.withCredentials",
	"crossDomain",
	"Ajax跨域"
]
date : "2018-06-27 12:20:00"
categories : [
    "cors"
]
menu : "main"
---

跨域问题是我们非常常见的问题，尤其在跨系统页面间的调用经常会遇到，解决的方式在网上一搜一大把，这里整理出我遇到跨域问题解决的方式以及思路，如何安全的解决跨域调用请继续往下看。

* [什么是跨域？](#what's-Cross-domain)
* [跨域使用的场景？](#scene)
* [解决跨域的方式？](#solution)
* [前端、后端如何配合处理跨域？](#solution1)
	* [跨域常见错误](#errors)
	* [突如其来的OPTIONS请求？](#options)
	* [后端需要返回的Header有哪些？](#response-header)
	* [前端如何配合发起请求？](#ajax-crossDomain)
	* [Ajax跨域请求跨平台兼容性问题](#ajax-compatibility)


# <span id = "what's-Cross-domain">什么是跨域？</span>

[什么是Cross-origin_resource_sharing?](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
跨域请求存在的原因：由于浏览器的同源策略，即属于不同域的页面之间不能相互访问各自的页面内容。

# <span id = "scene">跨域使用的场景？</span>

1. 域名不同
	* `www.jiuyescm.com`和`www.jiuye.com`即为不同的域名
2. 二级域名相同，子域名不同
	* `a.jiuyescm.com`和`b.jiuyescm.com`为子域不同
3. 端口不同，协议不同 
	* `http://www.jiuyescm.com`和`https://www.jiuyescm.com`
	* `www.jiuyescm.com:8888`和`www.jiuyescm.com:8080`

# <span id = "solution">解决跨域的方式？</span>

1. jsonp
	* 安全性差，已经不推荐
2. CORS（W3C标准，跨域资源共享 - Cross-origin resource sharing）
	* 服务端设置，安全性高，推荐使用
3. websocke
	* 特殊场景时使用，不属于常规跨域操作
4. 代理服务（nginx）
	* 可作为服务端cors配置的一种方式，推荐使用

# <span id = "solution1">前端、后端如何配合处理跨域？</span>

<span style="color:blue">*ps. 我们这里只介绍：CORS处理方式。*</span>

## <span id = "errors">跨域常见错误</span>

首先让我们看一下前端报出的跨域错误信息

第一种：`No 'Access-Control-Allow-Origin' header is present on the requested resource`，并且`The response had HTTP status code 404`

```
XMLHttpRequest cannot load http://b.domain.com, Response to preflinght request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://a.domain.com' is therefore not allowed access. The Response had HTTP status code 404.
```

<span style="color:blue">*ps.并且The response had HTTP status code 404*</span>

问题原因：服务器端后台没有允许OPTIONS请求

第二种：`No 'Access-Control-Allow-Origin' header is present on the requested resource`，并且`The response had HTTP status code 405`

```
XMLHttpRequest cannot load http://b.domain.com, Response to preflinght request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://a.domain.com' is therefore not allowed access. The Response had HTTP status code 405.
```

<span style="color:blue">*ps.并且The response had HTTP status code 405*</span>

问题原因：服务器端后台允许了OPTIONS请求，但是某些安全配置阻止了OPTIONS请求

第三种：`No 'Access-Control-Allow-Origin' header is present on the requested resource`，并且`The response had HTTP status code 200`

```
XMLHttpRequest cannot load http://b.domain.com, Response to preflinght request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://a.domain.com' is therefore not allowed access.
```

<span style="color:blue">*ps.并且The response had HTTP status code 200*</span>

问题原因：服务器端后台允许了OPTIONS请求，并且OPTIONS请求没有被阻止，但是头部不匹配。

第四种：`heade contains multiple values '*,*'`，并且`The response had HTTP status code 200`

```
XMLHttpRequestcannot load http://b.domain.com. The 'Access-Control-Allow-Origin' header contains multiple values'*, *', but only one is allowed. Origin 'http://a.domain.com' is therefore notallowed access.
```

<span style="color:blue">*ps.并且The response had HTTP status code 200*</span>

问题原因：设置多次Access-Control-Allow-Origin=*，可能是配置的人对CORS实现原理和机制不了解导致。

## <span id = "options">突如其来的OPTIONS请求？</span>

有时你会发现明明请求的是POST、GET、PUT、DELETE，但是浏览器中看到的确实OPTION，，为什么会变成OPTION？

原因：因为本次Ajax请求是“非简单请求”,所以请求前会发送一次预检请求(OPTIONS)，这个操作由浏览器自己进行。如果服务器端后台接口没有允许OPTIONS请求,将会导致无法找到对应接口地址，因此需要服务端提供相应的信息到response header中，继续往下看。

## <span id = "response-header">后端需要返回的Header有哪些？</span>

```
# 服务端允许访问的域名
Access-Control-Allow-Origin=https://idss-uat.jiuyescm.com
# 服务端允许访问Http Method
Access-Control-Allow-Methods=GET, POST, PUT, DELETE, PATCH, OPTIONS
# 服务端接受跨域带过来的Cookie,当为true时,origin必须是明确的域名不能使用*
Access-Control-Allow-Credentials=true
# Access-Control-Allow-Headers 表明它允许跨域请求包含content-type头，我们这里不设置，有需要的可以设置
#Access-Control-Allow-Headers=Content-Type,Accept
# 跨域请求中预检请求(Http Method为Option)的有效期,20天,单位秒
Access-Control-Max-Age=1728000
```

<span style="color:blue">_ps. 如果跨域需要携带cookie去请求，`Access-Control-Allow-Credentials`必须为true，但是需要注意当`Access-Control-Allow-Credentials=true`时，`Access-Control-Allow-Origin`就不能为" * " ，必须是明确的域名，当然可以多个域名使用 "," 分割_</span>

## <span id = "ajax-crossDomain">前端如何配合发起请求？</span>

如果是浏览器直接访问跨域请求url，只要服务端返回 “Access-Control-Allow-X” 系列header在response中即可成功访问。

如果是ajax发起的请求该如何处理？

第一种：请求不需要携带cookie

```
$.ajax({
    url : 'url',
    data : data,
    dataType: 'json',
    type : 'POST',
    crossDomain: true,
    contentType: "application/json",
    success: function (data) {
        var a=JSON.stringify(data);
        if(data.result==true){
        　　...........
    　　 }else{
　　　　 　　...........
　　　　 }
    },
    error:function (data) {
        var a=JSON.stringify(data);
        alert(a);
    }
});
```

<span style="color:blue">*ps. 增加crossDomain=true*</span>

第二种：请求需要携带cookie

```
$.ajax({
	url : 'url',
	data : data,
	dataType: 'json',
	type : 'POST',
	xhrFields: {
	    withCredentials: true
	},
	crossDomain: true,
	contentType: "application/json",
	success: function (data) {
        var a=JSON.stringify(data);
        if(data.result==true){
        　　...........
    　　 }else{
　　　　 　　...........
　　　　 }
    },
    error:function (data) {
        var a=JSON.stringify(data);
        alert(a);
    }
});
```

<span style="color:blue">*ps. 增加crossDomain与xhr.withCredentials，发送Ajax时，Request header中便会带上 Cookie 信息。*</span>

到这里你以为跨域的相关都介绍完毕了？太天真

最后还有一个终极boss问题，是什么问题呢？

上面的第二种携带cookie的跨域请求调用方式在IOS下可以正常工作，但是在Android下无法正常工作并且还报错，额。。。。。

## <span id = "ajax-compatibility">Ajax跨域请求跨平台兼容性问题</span>

问题原因：因为Android下的webview不兼容这个写法，使用标准的 [beforeSend(XHR)](http://www.w3school.com.cn/jquery/ajax_ajax.asp#beforeSend(XHR)) 替换

```
xhrFields: {
	withCredentials: true
}
```

<span style="color:blue">*ps. webview不兼容的写法，firefox下也不兼容*</span>

标准的写法：

```
$.ajax({
    type: "POST",
    url: "url",
    data:datatosend,
    dataType:"json",
    beforeSend: function(xhr) {
        xhr.withCredentials = true;
    }
    crossDomain:true,
    success: function (data) {
        var a=JSON.stringify(data);
        if(data.result==true){
        　　...........
    　　 }else{
　　　　 　　...........
　　　　 }
    },
    error:function (data) {
        var a=JSON.stringify(data);
        alert(a);
    }
});
```

到这跨域的相关使用就介绍完毕，这次是真的结束了。Keep Real!