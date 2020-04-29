---
toc : true
title : "Trouble Shooting —— HTTPS(SSL)站点使用WebSocket(ws)出现SecurityError问题"
description : "Trouble Shooting —— HTTPS(SSL)站点使用WebSocket(ws)出现SecurityError问题"
tags : [
	"WebSocket",
	"ssl",
	"wss",
	"ws",
	"SecurityError"
]
date : "2018-01-25 17:04:36"
categories : [
    "WebSocket"
]
menu : "main"
---

最近发生了一个问题我觉得挺有意思的，所以针对这个问题总结一下。

最近公司服务上了https(SSL)，在https(SSL)的环境下呢本因为可以愉快的玩耍，但是后来发现程序有使用websocket（ws://domain.com），这里就有朋友想了使用ws跟ssl有什么关系？我可以很明确的告诉你当然有关系。

当你的站点使用的是http的时候，使用ws可以很愉快的玩耍。当换成了https(SSL)那么问题来了。

在chrome下是测试没有问题可以正常使用，但是在ie下就出现了问题，报SecurityError的错误，那这个错误是什么原因呢?

```
WebSocket connection to 'ws://domain.com/websocket' failed: Error in connection establishment: net::ERR_CONNECTION_REFUSED
```

应该是每个浏览器对websocket的支持不一样或者说每个浏览器的安全沙箱不太一样，禁止了一些用法，各大浏览器对websocket的支持情况请看：[https://caniuse.com/#search=websocket](https://caniuse.com/#search=websocket)

无意中看到了mozilla的websocket支持详细说明如下：

<span style="color:red">
**Security considerations**<br>
WebSockets should not be used in a mixed content environment; that is, you shouldn't open a non-secure WebSocket connection from a page loaded using HTTPS or vice-versa. In fact, some browsers explicitly forbid this, including Firefox 8 and later.
</span>

具体地址：[https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications)

意思呢就是，ws与http对应，wss与https对应，如果站点使用的是https那就必须使用wss来做websocket请求不能使用ws来请求，不允许混合的方式使用。

看到这个就更加明确了问题所在：安全机制问题，最好不要混合使用避免奇怪的问题。

于是就开启了wss服务的使用路程。

如果你的wss服务是使用ip方式访问的，那么需要制作一个对应这个ip的证书，可以使用openssl生成自签名证书，但是不推荐使用ip的方式访问WebSocket。

如果你的wss服务是使用域名方式访问的，那么需要制作一个对应这个域名证书（最好是通配符域名证书），这样在构建wss服务的时候将证书配置进去。

构建wss服务有很多种方式，我这里提供一种比较简单的方式。

# 使用nginx提供ssl代理

保留以前的ws服务提供方式不做任何变更，增加一个nginx开启ssl代理，配置跟常规的ssl配置有一些细微的变化，那就是header会有一些变化，websocket需要指定`header：Upgrade`和`http version：1.1` ，因此我这里给出配置详情：

```
server {
    listen       443 ssl;
	server_name  your.domain.com;#你的域名，如果没有域名就去掉
	ssl on;
	#ssl_certificate     127.0.0.1.crt;
    #ssl_certificate_key 127.0.0.1.key;
	ssl_certificate     your.domain.com.pem;#这里可以使用pem文件和crt文件
    ssl_certificate_key your.domain.com.key;
	ssl_session_timeout 5m;
	ssl_session_cache shared:SSL:50m;
	ssl_protocols SSLv3 SSLv2 TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;

	location / {
		proxy_pass http://127.0.0.1:19808;# 这里换成你想转发的ws服务地址即可
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "Upgrade";
		proxy_set_header X-Real-IP $remote_addr;
        }
}
```

将证书文件放到conf同级目录即可，如果证书放在其他目录，需要修改ssl_certificate、ssl_certificate_key指定的位置。

这样就可以不用修改以前的ws服务来提供wss服务。

# 修改ws的请求方式为wss

```
wss://your.domain.com
```

ws服务这里也简单的说一下，有很多服务都可以构建ws服务，nginx、Workerman都可以，或者自己写程序开启ws服务。方式很多看个人喜好和公司的项目背景。

# 附录

1. [nginx官方文档](http://nginx.org/en/docs/)
2. [Openssl生成自签名证书，简单步骤](https://ningyu1.github.io/site/post/51-ssl-cert/)
3. [mozilla的websocket支持说明](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications)
4. [各大浏览器对websocket的支持情况](https://caniuse.com/#search=websocket)

# 常见错误

如果在ie下报如下错误：

```
IE Network Error 12038, 证书中的主名称无效或不相符
```

那是因为证书与请求地址不匹配导致的错误，在chrome测试它的https验证不会这么严格，在ie下https验证很严格（坑爹的ie）。