---
toc : true
title : "如何直接操作Docker容器？"
description : "如何直接操作Docker容器？"
tags : [
	"docker",
	"rancher"
]
date : "2018-01-11 16:11:36"
categories : [
    "docker"
]
menu : "main"
---

如果你想对Docker的容器进行操作，比如直接查看日志（`Rancher`无法看的时候），可以通过以下方式实现：

执行命令docker ps，找到该容器

第一种方式：

执行命令`docker exec -it [容器号前几位即可] /bin/bash`，进入容器内部（类似Linux环境），如：

![](/img/docker/1.png)

如果/bin/bash不能执行，那就用/bin/sh。换一种shell。

进入容器后我们就可以做任何事情，建议只在容器内做只读操作，必要进行修改操作。如果不想进入容器内部操作也可以：

执行命令`docker exec -it [容器号前几位即可] tailf -n 100 /xxxx/xxxxx.log`，进入容器内部（类似Linux环境），如：

![](/img/docker/2.png)

第二种方式：

执行命令`docker logs  [容器号前几位即可]`，查看日志

`docker logs --tail=200 -f 容器id`

ps:--tail=200 显示最近200行 ,all显示所有

这个可以用于不知道日志存放在哪里，如：

![](/img/docker/3.png)

或者直接去宿主机器上查看容器日志文件，docker会在主机上面的`/var/lib/docker/containers/[容器id]/`生成每个容器的日志文件，以[容器id]-json.log命名，<span style="color:red">**但是不推荐这种方式查看**</span>，如：

![](/img/docker/4.png)

在`/var/lib/docker/containers`能看到很多关于容器的信息比如说hostname等。

docker还支持Log Driver可以将日志接入到日志分析工具，比如说：ELKB套件


