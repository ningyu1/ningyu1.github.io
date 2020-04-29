---
toc : true
title : "Trouble Shooting —— Docker Pull Image : Filesystem layer verification failed for digest sha256错误"
description : "Trouble Shooting —— Docker Pull Image : Filesystem layer verification failed for digest sha256错误"
tags : [
	"docker",
	"docker pull",
	"Filesystem layer verification failed for digest sha256"
]
date : "2018-04-27 17:46:00"
categories : [
    "docker"
]
menu : "main"
---

# 问题现象

除了打包镜像的服务器上可以执行`docker pull 192.168.0.34:5000/sample:latest`以外，其它任何服务器执行此命令时，都会出现以下错误信息：

```
8b7054...: Verifying Checksum
Filesystem layer verification failed for digest sha256: 8b7054.....
```

这使得无法正常使用最新的`sample`镜像文件。

如果是按分析过程中的方式把`8b7054`文件夹迁移的话，`docker`会不断重试去拉取此文件信息，大概结果如下：

```
8b7054...: (..Retry 10 seconds)
Filesystem layer verification failed for digest sha256: 8b7054.....
```

# 分析过程

尝试在服务器上找日志，结果没有可用的日志。

在`/var/lib/registry`下找该`sha256`的数据，能够找到，尝试移走该文件夹数据。结果执行`docker pull`命令时，依旧是报错。只好迁移回文件夹。

尝试在网络上寻找解决方案，有的说与源有关系，有的说与`docker`版本有关系，需要升级版本，大多都没有很好的解决。如果实在搞不定，估计

需要考虑这些方案了。

尝试删除所有`sample`开发版本相关的`image`，并重新打包镜像，结果问题依旧。

# 解决方案

`docker build`的过程中有很多选项可以使用，尝试将缓存关闭（默认否）、签名关闭（默认否）、清理过程文件（默认是）。

因此切换到`jenkins`的`workspace`下，找到`sample`文件夹，执行以下命令:

```
docker build --rm=true --no-cache --disable-content-trust=true -t sample .
docker tag sample 192.168.0.34:5000/sample
docker push --disable-content-trust=true 192.168.0.34:5000/sample
```

编译打包过程没有任何错误，可以正常发布镜像到`registry`上。

于是，切换到其他服务器上去执行`docker pull`，结果一切正常。

![](/img/docker-registry/8.png)

没有`checksum`？ 且没有原来失败的`sha256 digest`。

看了下其他镜像成功过的pull日志，也是没有`checksum`。看来只有出现异常的时候，才会去`checksum`（待考证）

既然已经成功过，那还是用正常的方式去打包编译及下载。于是删除现有镜像文件，在`jenkins`上进行工程打包（原始逻辑）。

```
docker build -t sample:latest .
docker tag sample:latest 192.168.0.34:5000/sample:latest
docker push 192.168.0.34:5000/sample:latest
```

打包好后，在其它服务器上执行`docker pull`，一样可以正常使用了。

# 总结

问题最终通过`docker`创建镜像时增加了关闭缓存、关闭校验的参数（`--rm=true --no-cache --disable-content-trust=true`），然后构建出来的镜像`push`到`registry`去重写这个镜像的最新`digest`值，再重新去掉这些参数再次构建镜像（恢复成正常构建镜像命令）后重新`push`到`registry`。这个问题看样子是由于新构建的镜像无法修改`registry`上的`digest`值导致`pull`的时候报错。