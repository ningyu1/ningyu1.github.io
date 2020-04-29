---
toc : true
title : "Java开源APM概要"
description : "Java开源APM概要"
tags : [
	"APM",
	"pinpoint",
	"cat",
	"sky walking"

]
date : "2017-12-11 10:00:36"
categories : [
    "APM"
]
menu : "main"
---

# 候选APM

* [naver/pinpoint](https://github.com/naver/pinpoint)(github上2148个star)

韩国的一个公司开源的，有待评估使用情况，就是整体还不是JDK8，有些还是有点费劲，技术上采用agent的方式，对java友好

* [大众点评cat](https://github.com/dianping/cat)(github上1725个star)

看接入的公司还是挺多的，个人感觉是点评名气还可以，但是搭建起来有点费劲，很多东西都写死配置了，不灵活。整体设计的话，由于没有采用agent的方式，采用的是api手工埋点的方式，跟SNG的很像，好处的是跨语言，不好的地方就是对java来说用起来还需要包装一下

* [sky-walking](https://github.com/wu-sheng/sky-walking)(github上374个star)

开发团队加入了OneAPM,目前看使用的公司不多，整体技术采用agent方式，对java友好。提供了对dubbo等的支持，属于soa时代的产品

# 技术架构

## pinpoint

![](/img/apm/1.png)

## CAT

![](/img/apm/2.png)

## skywalking

![](/img/apm/3.png)

## 简要评价

从技术架构上看，对于log的存储都使用了hbase，也都是自己实现了日志/监控数据的上报。pinpoint支持udp的方式，这个好一点。这类还是有点SOA时代的痕迹，更为符合大数据时代的做法是，监控数据丢给kafka，然后监控server来消费数据即可，这一点在cat中使用了consumer有点这个味道，但是没有彻底转型过来。

## 展望

APM整体的功能结构，主要是 1.日志追踪，2.监控报警 3.性能统计。对于日志追踪，已经有spirng cloud zipkin了，这个对spring cloud体系结合的很好，确的就是监控报警和性能统计，可以采用agent的方式进行无侵入的监控，或者采用log appender的方式到kafka，之后再进行error的监控报警，以及把performance的数据log到日志，发送到kafka来进行统计。

## docs

* [pinpoint](https://github.com/naver/pinpoint)
* [大众点评Cat--架构分析](http://blog.csdn.net/szwandcj/article/details/51025669)
* [透过CAT，来看分布式实时监控系统的设计与实现](http://www.infoq.com/cn/articles/distributed-real-time-monitoring-and-control-system)
* [sky-walking](https://github.com/wu-sheng/sky-walking)



转自原文地址：https://segmentfault.com/a/1190000006817114