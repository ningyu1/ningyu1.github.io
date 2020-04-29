---
toc : true
title : "Docker启动的容器如何清理日志？看这里"
description : "Docker启动的容器如何清理日志？看这里"
tags : [
	"docker"
]
date : "2018-06-19 15:10:00"
categories : [
    "docker"
]
menu : "main"
---

Docker run起来的容器随着时间久了，容器内的服务输出的日志也在日积月累，需要定期的进行日志清理。

如果公司使用DevOps的话更加需要对容器内的日志进行定期清理，业务的镜像服务或许还好一些，因为开发同学每天都在用、每天都会upgrade服务，在upgrade的时候会删除老的容器，再重新run一个新容器去替换掉老的，但是有一些长期run的服务就很少有人关注了，比如说rancher、还有一些基础服务，可能很长时间也不会去做upgrade操作，因此容器内的日志就越来越多，如果不清理总有一天会撑爆服务器硬盘，到那个时候再去清理恢复服务的话，有可能会有磁盘文件损坏的风险。

因此我们需要定期的对Docker容器内的日志进行清理。

如何查看Docker内容器的日志？可以参考文章：[《如何直接操作Docker容器？》](https://ningyu1.github.io/site/post/48-docker/)

在清理容器日志前，我们首先要知道Docker将容器的日志放在那里？

Docker将容器的日志放在`/var/lib/docker/containers/containerid/containerid-json.log`

<span style="color:blue">*ps. containerid是容器id一般是`82bbc....`这个风格，64位字符*</span>

当然找不到的话也可以使用文件搜索的方式去查找Docker的容器日志放在那里，查找的时候按照上面的名称风格去查找，例如：

```
find / -type f -name "*-json.log"
```

容器的id怎么查看呢？

```
docker ps
```

通过ps找到容器id，也找到日志所在的位置后，接下来就是清理日志的操作了，日志文件不能直接删除，直接删除会影响正在运行的容器，可以通过清空文件内容的方式来处理。

清空文件的方式有很多种如下：

```
$ : > filename 
$ > filename 
$ echo "" > filename 
$ echo > filename 
$ cat /dev/null > filename
```

选一种即可

```
cat /dev/null >/var/lib/docker/containers/containerid/containerid-json.log
```
