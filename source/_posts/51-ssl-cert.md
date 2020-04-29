---
toc : true
title : "Openssl生成自签名证书，简单步骤"
description : "Openssl生成自签名证书，简单步骤"
tags : [
	"ssl",
	"openssl"
]
date : "2018-01-12 17:06:36"
categories : [
    "ssl"
]
menu : "main"
---

最近在调试服务时需要使用证书，因此对证书的生成和使用做了一些整理，网上关于这部分资料也很多，但是很杂乱，我整理出以下简单的步骤生成自签名证书，具体让我们来看一看吧。

# 第一种方式

通过openssl生成私钥

```
openssl genrsa -out server.key 1024
```

使用私钥生成自签名的cert证书文件，以下是通过参数只定证书需要的信息

```
openssl req -new -x509 -days 3650 -key server.key -out server.crt -subj "/C=CN/ST=mykey/L=mykey/O=mykey/OU=mykey/CN=domain1/CN=domain2/CN=domain3"
```

如果对上面参数具体的说明不太了解的，可以使用不带参数的方式，通过命令行步骤生成，参考第二种方式。

# 第二种方式

通过openssl生成私钥

```
openssl genrsa -out server.key 1024
```

根据私钥生成证书申请文件csr

```
openssl req -new -key server.key -out server.csr
```

这里根据命令行向导来进行信息输入：

![](/img/ssl-cert/1.png)

<span style="color:red">**ps.Common Name可以输入：*.yourdomain.com，这种方式生成通配符域名证书**</span>

使用私钥对证书申请进行签名从而生成证书

```
openssl x509 -req -in server.csr -out server.crt -signkey server.key -days 3650
```

这样就生成了有效期为：10年的证书文件，对于自己内网服务使用足够。

# 第三种方式

直接生成证书文件

```
openssl req -new -x509 -keyout server.key -out server.crt -config openssl.cnf
```

<span style="color:red">**ps.以上生成得到的server.crt证书，格式都是pem的。**</span>

我个人比较推荐使用第二种方式，如果不在乎其他参数可以使用第三种直接一步生成。

