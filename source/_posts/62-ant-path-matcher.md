---
toc : true
title : "RESTful访问权限管理实现思路，采用路径匹配神器之AntPathMatcher"
description : "RESTful访问权限管理实现思路，采用路径匹配神器之AntPathMatcher"
tags : [
	"antPathMatcher",
	"restful"
]
date : "2018-02-27 16:15:49"
categories : [
	"restful"
]
menu : "main"
---


我们经常在写程序时需要对路径进行匹配，比如说：资源的拦截与加载、`RESTful`访问控制、审计日志采集、等，伟大的`SpringMVC`在匹配`Controller`路径时是如何实现的？全都归功于ant匹配规则。

`Spring`源码之`AntPathMatcher`，这个工具类匹配很强大，采用的是ant匹配规则。

什么是ant匹配规则？

|字符wildcard|描述|
|:--|:--|
|?|匹配一个字符（matches one character）|
|*|匹配0个及以上字符（matches zero or more characters ）|
|**|匹配0个及以上目录directories（matches zero or more 'directories' in a path ）|

这个匹配规则很简单，采用简洁明了的方式来进行匹配解析，简化版本的正则。

结合官方的示例来理解一下

|Pattern|匹配说明|
|:--|:--|
|com/t?st.jsp |匹配: com/test.jsp  ,  com/tast.jsp  ,  com/txst.jsp|
|com/*.jsp  |匹配: com文件夹下的全部.jsp文件|
|com/**/test.jsp |匹配: com文件夹和子文件夹下的全部.jsp文件|
|org/springframework/**/*.jsp |匹配: org/springframework文件夹和子文件夹下的全部.jsp文件|
|org/**/servlet/bla.jsp |匹配: org/springframework/servlet/bla.jsp  , org/springframework/testing/servlet/bla.jsp  ,  org/servlet/bla.jsp |

## 如何实现RESTful访问权限管理？

在微服务和前后端分离的开发模式下，往往会使用`RESTful`来开发后端服务，那服务的访问权限控制就是一个问题，那下来我们就说一下如何实现`RESTful`访问权限管理。

## 权限资源类型

资源分为如下两种类型：

* `public`（公有）：`public`为不控制访问的资源
* `private`（私有）：`private`为需要被控制访问的资源

<span style="color:blue">*ps.这种方式资源管理的相对严格一些，如果想管理的粗矿一些，可以不需要public，只要在private中未找到的资源就是不控制访问的资源即可，实现时可以根据自己的业务场景来调整。*</span>

## 匹配原则

基础匹配规则：使用ant匹配规则

在`SpringMVC`的路径匹配原则中有一个原则是：最长匹配原则(has more characters)

什么是最长匹配原则(has more characters)？

最长匹配原则(has more characters)简单的理解就是目标`URL`有多个`pattern`都可以匹配上就取最长的那个`pattern`

例如：请求的`URL`为`/app/dir/file.jsp`，有两个`pattern` `/**/*.jsp`和`/app/dir/*.jsp`都可以匹配成功，那么会根据`pattern`的长度来控制是否采用哪一个，这里使用`/app/dir/*.jsp`来匹配。

为什么要使用最长匹配原则？我的理解是长的`pattern`更符合目标`URL`格式，短的`pattern`往往是范围较广的，匹配取最适合的`pattern`也是比较符合预期的。

## 根据服务名分类

在做资源访问权限时往往会有多个服务可能会出现相同的资源路径，因此增加一级服务名来对资源进行分类。

例如：`GET /v1/service1/product/1` 和 `GET /v1/service2/product/1`，根据二级目录`service`名称来对服务进行模块化分割。`/v1`为RESTful版本号

<span style="color:blue">*ps.服务名就是为了做资源分类*</span>

## 权限验证逻辑

* 验证`public`资源
	* 去除末尾`"/"`
	* 验证`service`服务名，服务名为空返回没有权限
	* 获取服务名下`enabled=true`的资源表，结果进行`cache`，结果为空没有权限
	* 根据`pattern`长度倒序
	* 匹配`method`，匹配成功进行下一步匹配
	* 匹配请求的`url`，匹配成功返回有权限，反之返回没有权限
* 验证`private`资源
	* 去除末尾`"/"`
	* 验证`service`服务名，服务名为空返回没有权限
	* 获取服务名下用户角色对应的资源列表聚合结果，结果进行`cache`，结果为空返回没有权限
	* 根据`pattern`长度倒序
	* 匹配`method`，匹配成功进行下一步匹配，反之`continue`
	* 匹配请求的`url`，匹配成功进行下一步匹配，反之`continue`
	* 检查匹配成功的`url`是否为禁用状态，如果禁用返回无权限，反之进行下一步匹配
	* 匹配成功的`url`对应的角色列表进行登录用户的角色匹配
	* 角色匹配成功返回有权限，反之返回没有权限

<span style="color:blue">*ps.method是`GET`、`POST`、`PUT`、`PATCH`、`DELETE`，`service`是服务模块名*</span>

## 缓存结构

* private资源数据
	* 结构：`hash`
	* `cache key=${APPNAME}.METADATA.RESOURCE`，`field=${RESOURCE_ID}`，`value=Resource`对象
* public资源数据
	* 结构：`hash`
	* `cache key=${APPNAME}.METADATA.RESOURCE.PUBLIC`，`field=${SERVICE}`，`value=List<Resource>`
* 用户关联角色数据
	* 结构：`hash`
	* `cache key=${APPNAME}.METADATA.ROLE`，`field=${USER_ID}`，`value=List<ROLE_ID>`
* 角色关联的资源数据
	* 结构：`hash`
	* `cache key=${APPNAME}.METADATA.MAPPING`，`field=${SERVICE}`，`value=List<Metadata<Resource,List<ROLE_ID>>>`
	* 这里存储的数据结构是反向的，获取服务下的资源列表，每个资源数据中会有拥有这个资源的角色列表。

<span style="color:blue">*ps.缓存可以使用分布式的`redis`、`redisson`、如果单机可以使用`jvm cache`。*</span>

## 缓存控制

* private资源数据发生变更时
	* 调用`MetadataCache.invalidResources()`，失效`cache key=${APPNAME}.METADATA.RESOURCE`下所有数据
* public资源数据发生变更时
	* 调用`MetadataCache.invalidPublicResource(service)`失效服务名下的`public`资源集合，失效`cache key=${APPNAME}.METADATA.RESOURCE.PUBLIC`下的某个`${SERVICE}`数据
	* 调用`MetadataCache.invalidPublicResource()`失效所有服务名下的`public`资源集合，失效`cache key=${APPNAME}.METADATA.RESOURCE.PUBLIC`下所有数据
* 用户关联角色数据发生变更时
	* 调用`MetadataCache.invalidUserRoles(userId)`失效用户下的角色集合，失效`cache key=${APPNAME}.METADATA.ROLE`下所有数据
* 角色关联的资源数据发生变更时
	* 调用`MetadataCache.invalidMetadata(service)`失效服务名下的资源角色聚合对象，失效`cache key=${APPNAME}.METADATA.MAPPING`下的某个`${SERVICE}`数据
	* 调用`MetadataCache.invalidMetadata()`失效所有服务名下的资源角色聚合对象，失效`cache key=${APPNAME}.METADATA.MAPPING`下所有数据

<span style="color:blue">*ps.在以上触发点上对缓存数据进行更新，这里采用失效再加载方式*</span>

## 缓存加载

* `private`资源数据，在系统启动加载，加载所有私有资源，如果失效了，会在`private`匹配的时再进行加载
* `public`资源数据，在`public`匹配时加载，通过服务名加载，如果失效了，会在`public`匹配时再进行加载
* 用户关联角色数据，在`private`匹配时加载，如果失效了，会在`private`匹配时再进行加载
* 角色关联的资源数据，在`private`匹配时加载，如果失效了，会在`private`匹配时再进行加载

<span style="color:blue">*ps.资源数据加载触发点*</span>

## pattern配置建议

* 配置资源时，将不需要配置权限的url配置为`public`资源
* 每个服务名下建议配置一个`**`（双星）通配符给超级管理员使用，例如：`/v1/products/**`
* 每个`url`的第二级目录要与服务名一致，例如：`/v1/products/{pid}`，服务名为`products`
* `url`的目录结构必须大于两级目录，例如：`/v1/products/{pid}`，不允许为：`/v1/{pid}`
* `url`与权限通配符映射关系，前面`url`，后面`pattern`
	* 例如：`/v1/products/{pid}` -> `/v1/products/*`
	* 例如：`/v1/products/{pid}/skus/{sid}` -> `/v1/products/*/skus/*`
	* 例如：`/v1/products/enabled` -> `/v1/products/enabled`
	* 例如：`/v1/products/**`，匹配`products`目录下所有目录


**以上就是一种RESTful资源管理的实现思路，能控制到RESTful的方法级别，在前后端分离的项目可以使用这种方式来控制访问权限。**


