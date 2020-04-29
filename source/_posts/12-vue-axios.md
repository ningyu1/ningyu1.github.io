---
toc : true
title : "关于Axios的GET与DELETE用法注意事项"
description : "关于Axios的GET与DELETE用法注意事项"
tags : [
    "Vue.js",
    "Axios"

]
date : "2017-08-24 10:51:30"
categories : [
    "Vue"
]
menu : "main"
---


## axios的接口定义如下

![vue1](/img/vue-axios/1.png)

## config定义如下：

![vue2](/img/vue-axios/2.png)

因此，我们在使用get和delete时需要注意，这两个接口接收的第二个参数是config。用时，就需要区别对待，且需要与后台定义对应。

1. 如果想参数在Query Parameter里面，那就用{params: params}，后台那边会用RequestParam接收
2. 如果想参数在Payload里面，那就用{data: params}，后台那边会用RequestBody接收

如果后台不匹配，可能会抛ContentType错误的异常，如：

![vue3](/img/vue-axios/3.png)