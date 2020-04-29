---
toc : true
title : "Docker Registry镜像清理问题"
description : "Docker Registry镜像清理问题"
tags : [
	"docker",
	"docker registry",
	"docker registry web",
	"docker registry frontend"

]
date : "2017-12-29 14:45:36"
categories : [
    "docker"
]
menu : "main"
---

# 目录

1. [修改Docker Registry配置](#config)
2. [使用Registry V2 RestfulAPI 删除镜像](#restful)
3. [Docker Registry GC回收空间](#gc)
4. [使用UI管理Docker Registry](#ui)

# <a name="config">修改Docker Registry配置</a>

配置开启删除功能:config.yml

```
version: 0.1
log:
  fields:
    service: registry
storage:
    delete:
        enabled: true
    cache:
        blobdescriptor: inmemory
    filesystem:
        rootdirectory: /var/lib/registry
http:
    addr: :5000
    headers:
        X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

<span style='color:red'>**主要在storage下增加delete开启状态 enabled:true**</span>

具体配置参考官方配置详情：[https://github.com/docker/distribution/blob/master/docs/configuration.md](https://github.com/docker/distribution/blob/master/docs/configuration.md)

# <a name="restful">使用Registry V2 RestfulAPI 删除镜像</a>

镜像删除之前需要获取镜像的digest值

* 获取镜像digest值

```
curl --cacert /etc/docker/certs.d/192.168.0.34\:5000/ca.crt -H "Accept:application/vnd.docker.distribution.manifest.v2+json" https://192.168.0.34:5000/v2/messer/manifests/1.0
```

注意：

我们配置了证书，所以必须要添加证书 --cacert使用crt证书

在获取镜像digest值时必须要指定Header "Accept:application/vnd.docker.distribution.manifest.v2+json" 否则无法获取

RESTful API格式：

```
/v2/<镜像名称>/manifests/<tag>
```

具体Docker registry V2 RESTful API查看：[https://docs.docker.com/registry/spec/api/](https://docs.docker.com/registry/spec/api/)

* 通过上面获取到的具体返回信息

```
{
   "schemaVersion": 2,
   "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
   "config": {
      "mediaType": "application/octet-stream",
      "size": 4191,
      "digest": "sha256:c8043677c5d750e0904298c29825d1da8389a1ea2e2564e076ed54a023ece056"
   },
   "layers": [
      {
         "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
         "size": 51363125,
         "digest": "sha256:75a822cd7888e394c49828b951061402d31745f596b1f502758570f2d0ee79e2"
      },
      {
         "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
         "size": 20179224,
         "digest": "sha256:0aefb9dc4a57d3de6a9cfa2e87e4502dfa8ce3876264bb20783b1610f8e44806"
      },
      {
         "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
         "size": 193,
         "digest": "sha256:046e44ee6057f1264d00b0c54adcff2f2c44d30a29b50dfef928776f7aa45cc8"
      },
      {
         "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
         "size": 596,
         "digest": "sha256:614a7b3525a1442775b9d1b52413024dc750b6a9169fcae8d4ef9cf98bda7f0f"
      },
      {
         "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
         "size": 1083978,
         "digest": "sha256:5fe57df972ae5e10f02783cb372841e6feab67a296e2abc16f9a868e4322c33d"
      }
   ]
}
```

我们要的就是`"digest": "sha256:c8043677c5d750e0904298c29825d1da8389a1ea2e2564e076ed54a023ece056"`这个值

* 通过delete接口删除镜像

```
curl --cacert /etc/docker/certs.d/192.168.0.34\:5000/ca.crt -X DELETE https://192.168.0.34:5000/v2/messer/manifests/sha256:c8043677c5d750e0904298c29825d1da8389a1ea2e2564e076ed54a023ece056
```

返回不是404 就是删除了

具体Docker registry V2 RESTful API查看：[https://docs.docker.com/registry/spec/api/](https://docs.docker.com/registry/spec/api/)

# <a name="gc">Docker Registry GC回收空间</a>

但是实际上并没有删除，只是删除了 Registry 的索引。实际文件并没有删除。

最后还需要执行镜像的垃圾回收：

```
registry garbage-collect /etc/docker/registry/config.yml
```

上面需要进入到registry容器里面去执行，/etc/docker/registry/config.yml为配置文件路径

gc完后会看到被gc的信息例如：

```
root@83d6f5acc9f5:/# /bin/registry garbage-collect /etc/docker/registry/config.yml
INFO[0013] Deleting blob: /docker/registry/v2/blobs/sha256/c0/c0c9ad6136b5e7b142c48c7167eede3d15af54c538f7f3177c50693006cca242  go.version=go1.6.2 instance.id=73c88c92-c196-413e-9cdf-413760de2a62
INFO[0013] Deleting blob: /docker/registry/v2/blobs/sha256/0c/0c1f3512513001c7e37c0dff11064a5c76ad9098507ee74189d6a810742173d7  go.version=go1.6.2 instance.id=73c88c92-c196-413e-9cdf-413760de2a62

```

如果没有任何输出证明没有回收到任何东西。

# <a name="ui">使用UI管理Docker Registry</a>

上面是通过Docker registry V2 RESTful API的方式删除，也可以通过UI工具删除，目前Docker registry UI工具也比较多这里介绍两个， docker-registry-frontend和hyper/docker-registry-web。

## docker-registry-frontend

我们使用的是 docker-registry-frontend但是他的功能比较弱没有删除的操作，只能浏览，虽然他的说明里面有说明添加了删除功能但是发布的版本中并没有合并删除功能的代码：

官方hub信息：[https://hub.docker.com/r/konradkleine/docker-registry-frontend/](https://hub.docker.com/r/konradkleine/docker-registry-frontend/)

![](/img/docker-registry/1.png)

这个`MODE_BROWSE_ONLY=false`这个配置是完全没有效果的，今天可以查看docker-registry-frontend的github issue：[https://github.com/kwk/docker-registry-frontend/issues/106](https://github.com/kwk/docker-registry-frontend/issues/106)

## hyper/docker-registry-web

这个UI虽然不是很好看，但是有删除功能

官方hub信息：[https://hub.docker.com/r/hyper/docker-registry-web/](https://hub.docker.com/r/hyper/docker-registry-web/)

创建步骤根据官方hub上面的说明信息一步一步做就ok了，但是这个东西做的不太好速度有点慢。

界面预览：

![](/img/docker-registry/2.png)
![](/img/docker-registry/3.png)
![](/img/docker-registry/4.png)
![](/img/docker-registry/5.png)

不管是通过RESTful API还是UI删除镜像，都需要去再registry里去gc一下才能真正释放空间，如下时候gc后的效果图

![](/img/docker-registry/6.png)
![](/img/docker-registry/7.png)


