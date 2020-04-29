---
toc : true
title : "如何免费的让你的网站变得更加安全 - HTTPS"
description : "如何免费的让你的网站变得更加安全 - HTTPS"
tags : [
	"https",
	"lets-encrypt"
]
date : "2018-05-28 15:57:00"
categories : [
    "https"
]
menu : "main"
---

在这个数据不安全的世界里，很有可能你早上买了个东西下午就会有类似的推销电话打过来骚扰你，这些数据信息从哪里来的呢？当然很多时候是人为的贩卖信息造成的，但是数据来源很大一部分是来自于互联网。因此站点使用https已经是最基本的防护，当我去访问一个站点它如果不是https的我可能都不想访问它更别提输入一些个人信息了。那怎么才能让我们提供的网站安全的服务你的用户呢？当然是使用证书来保护网站来往的数据。

如果不差钱的话还是使用收费的证书去给你的网站开启https。当然国内也有很多免费的证书，去谷哥或者度娘能检索到一大把的免费证书信息，各大云服务商上面也有免费的证书可以申请使用，我下面就介绍一个免费的使用方式。

[Let’s Encrypt](https://letsencrypt.org/)

`Let's Encrypt`是一个于2015年三季度推出的[数字证书认证机构](https://zh.wikipedia.org/wiki/%E6%95%B0%E5%AD%97%E8%AF%81%E4%B9%A6%E8%AE%A4%E8%AF%81%E6%9C%BA%E6%9E%84)，旨在以自动化流程消除手动创建和安装证书的复杂流程，并推广使[万维网](https://zh.wikipedia.org/wiki/%E8%90%AC%E7%B6%AD%E7%B6%B2)服务器的加密连接无所不在，为安全网站提供免费的[SSL](https://zh.wikipedia.org/wiki/SSL)/[TLS](https://zh.wikipedia.org/wiki/TLS)证书。

`Let's Encrypt由`[互联网安全研究小组](https://zh.wikipedia.org/w/index.php?title=%E4%BA%92%E8%81%94%E7%BD%91%E5%AE%89%E5%85%A8%E7%A0%94%E7%A9%B6%E5%B0%8F%E7%BB%84&action=edit&redlink=1)（缩写ISRG）提供服务。主要赞助商包括[电子前哨基金会](https://zh.wikipedia.org/wiki/%E7%94%B5%E5%AD%90%E5%89%8D%E5%93%A8%E5%9F%BA%E9%87%91%E4%BC%9A)、[Mozilla基金会](https://zh.wikipedia.org/wiki/Mozilla%E5%9F%BA%E9%87%91%E4%BC%9A)、[Akamai](https://zh.wikipedia.org/wiki/Akamai)以及思科。2015年4月9日，ISRG与Linux基金会宣布合作。

通过官网我们能看到赞助商还是蛮多的，[赞助商列表](https://letsencrypt.org/sponsors/)

上述来自于维基百科，[查看原文](https://zh.wikipedia.org/wiki/Let%27s_Encrypt)

从介绍中能了解到它是为了解决，<span style="color:blue">***以自动化流程消除手动创建和安装证书的复杂流程***</span>，让证书使用更加简单。

我们通过`Let's Encrypt`官网的[Getting Started](https://letsencrypt.org/getting-started/)中可以查看具体的使用说明

下面我们简单介绍一下使用步骤：

# 使用步骤

安装证书非常简单，只需要使用[Certbot](https://certbot.eff.org/)，就可以完成。

* 打开[Certbot](https://certbot.eff.org/)，选择你的网站使用的应用服务器和操作系统。如下图：

![](/img/certbot/1.png)

* 选择完后会生成安装教程，不用想太多Step by step就好了，如下图：

![](/img/certbot/2.png)

## 安装基础环境

```
$ sudo apt-get update
$ sudo apt-get install software-properties-common
$ sudo add-apt-repository ppa:certbot/certbot
$ sudo apt-get update
$ sudo apt-get install python-certbot-nginx 
```

## 安装证书

安装完之后直接运行`sudo certbot --nginx`即可

<span style="color:blue">`certbot` 会自动修改nginx配置文件(`nginx.conf`)并且列出你的虚拟站点让你选择是否开启HTTPS，当然你只用选择是否开启即可，选择完后它会自动下载证书并且修改nginx配置文件</span>

修改后的nginx.conf是什么样的？让我们看一下

```
listen 443 ssl; # managed by Certbot
ssl_certificate /etc/letsencrypt/live/your.domain/fullchain.pem; # managed by Certbot
ssl_certificate_key /etc/letsencrypt/live/your.domain/privkey.pem; # managed by Certbot
include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
```

还会很贴心的帮你生成http跳转到https的配置，如下：

```
# Redirect non-https traffic to https
if ($scheme != "https") {
  return 301 https://$host$request_uri;
} # managed by Certbot
```

到这里就完成了证书安装，是不是很简单。当然我们之前也说过证书是有有效期的，那过期了之后我们如何操作？再根据上面的操作执行一次？

当然不是了，我们可以使用自动检测的方式来进行自动的更新证书与nginx配置。具体看下面操作：

## 证书自动更新

下面是官方对于证书续订的说明：

```
Automating renewal
The Certbot packages on your system come with a cron job that will renew your certificates automatically before they expire. 
Since Let's Encrypt certificates last for 90 days, it's highly advisable to take advantage of this feature. 
You can test automatic renewal for your certificates by running this command:

$ sudo certbot renew --dry-run
```

首先`Let’s Encrypt` 的证书只有90天的有效期，所以我们可以使用`crontab`来进行定时自动更新。

`crontab`如何使用这里就不多做介绍了，可以查看[crontab使用说明](https://ningyu1.github.io/linux-command/c/crontab.html)

使用下面的表达式让其在每个月的一号强制更新证书，但是证书的强制更新不能太频繁，太频繁会提前进入证书授权限制。

```
0 0 1 * * /usr/bin/certbot renew --force-renewal
10 0 1 * * /usr/sbin/service nginx restart
```

[renew的使用说明](https://certbot.eff.org/docs/using.html#renewal)


到这里证书安装以及自动更新就介绍完毕了，当然我们的站点中有很多静态资源或超链接的地方，在启用https后可能也要进行一轮的检查由http修改为https，主要就是那些hard code的地方需要找出来进行修改掉。

为了保护你服务的用户信息安全，我强烈建议开启HTTPS，只要是个站点服务就应该开启HTTPS这才是负责任的的体现，Keep Real。




