---
toc : true
title : "Trouble Shooting —— Docker Pull Image : error pulling image configuration: unexpected EOF错误"
description : "Trouble Shooting —— Docker Pull Image : error pulling image configuration: unexpected EOF错误"
tags : [
	"docker",
	"docker pull",
	"error pulling image configuration: unexpected EOF"
]
date : "2018-05-29 12:09:00"
categories : [
    "docker"
]
menu : "main"
---

# 问题现象

执行docker pull命令报错：

```
docker@rancher-192:~$ docker pull 192.168.0.34:5000/imageName:latest
latest: Pulling from imageName
75a822cd7888: Pulling fs layer
046e44ee6057: Download complete
8c47541cb10b: Waiting
e17edf9a1bd4: Waiting
error pulling image configuration: unexpected EOF
```

查看日志错误如下：

```
docker@rancher-192:~$ journalctl -u docker.service
-- Logs begin at Mon 2018-05-14 04:14:07 CST, end at Tue 2018-05-29 11:31:02 CST. --
May 29 11:28:22 rancher-192.168.0.83 docker[993]: time="2018-05-29T11:28:22.601383366+08:00" level=error msg="Not continuing with pull after error: error pulling image configuration: unexpected EOF"
May 29 11:30:36 rancher-192.168.0.83 docker[993]: time="2018-05-29T11:30:36.987345560+08:00" level=error msg="Not continuing with pull after error: error pulling image configuration: unexpected EOF"
```

随便找一台其他机器上进行pull操作，一样报错，但是pull其他镜像确实正常的，查看其他机器上日志如下：

```
docker@devserver1:~/messer/public$ journalctl -u docker.service
-- Logs begin at Fri 2018-05-25 23:29:13 CST, end at Tue 2018-05-29 11:34:24 CST. --
May 29 11:34:24 devserver1 docker[893]: time="2018-05-29T11:34:24.167053102+08:00" level=error msg="Not continuing with pull after error: error pulling image configuration: unexpected EOF"
May 29 11:34:24 devserver1 docker[893]: time="2018-05-29T11:34:24.212480193+08:00" level=info msg="Layer sha256:3fc67fe0621339e8f025cb429eecee5db64025673f3eafb02d12b512f07bbba5 cleaned up"
```

这个问题让我们想到了之前我写过一篇文章[《Trouble Shooting —— Docker Pull Image : Filesystem layer verification failed for digest sha256错误》](https://ningyu1.github.io/site/post/79-docker-registry-pull-filesystem-layer/)也是`docker pull`的时候报错：

```
8b7054...: Verifying Checksum
Filesystem layer verification failed for digest sha256: 8b7054.....
```

通过使用之前文章的解决方案依然可以解决这个问题。

这类问题可以使用绕过校验重新build后push刷新digest值后，恢复原始build参数再重新push恢复默认操作来进行解决。


