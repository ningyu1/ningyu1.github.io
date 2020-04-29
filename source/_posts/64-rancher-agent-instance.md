---
toc : true
title : "Trouble Shooting —— Docker rancher/agent-instance cannot start automatically"
description : "Trouble Shooting —— Docker rancher/agent-instance cannot start automatically"
tags : [
	"trouble shooting",
	"docker",
	"rancher",
	"rancher/agent:v1.0.2",
	"rancher/agent-instance:v0.8.3"
]
date : "2018-03-05 17:23:11"
categories : [
	"rancher",
	"docker"
]
menu : "main"
---


今天发现一个`docker`机器莫名其妙的无工作了，于是进入宿主机查看信息如下：

```
docker@xxx:~$ docker ps
be4238200956        rancher/agent:v1.0.2                          "/run.sh run"            5 months ago        Up 34 minutes                                                              rancher-agent

```

发现只有一个`rancher/agent`容器是启动的，其余的都没有启动，查看`rancher`控制台，服务都在转圈圈`Restaring`状态，而且长时间一直这个状态没有变化。

这是什么问题呢？

查看机器上所有的容器

```
docker@xxx:~$ docker ps -a
CONTAINER ID        IMAGE                                         COMMAND                  CREATED             STATUS                        PORTS               NAMES
d9da7f16ef2d        192.168.0.34:5000/saas-erp:latest             "./entrypoint.sh"        4 days ago          Exited (0) 50 minutes ago                         r-erp_erp-dubbo_1
79e8e475db19        192.168.0.34:5000/tms2job:latest              "./entrypoint.sh"        4 weeks ago         Exited (0) 50 minutes ago                         r-tms_tms2-job_1
0995dabe324b        192.168.0.34:5000/customer-mq:latest          "catalina.sh run"        8 weeks ago         Exited (143) 7 weeks ago                          r-customer_customer-mq_1
65492930b132        192.168.0.34:5000/saas-account:latest         "./entrypoint.sh"        9 weeks ago         Exited (0) 50 minutes ago                         r-account_account-dubbo_1
248514cd635a        192.168.0.34:5000/saas-erp-http-main:latest   "./entrypoint.sh"        4 months ago        Exited (0) 50 minutes ago                         r-erp_erp-http-main_1
94e51332cc40        192.168.0.34:5000/zookeeper:elevy             "/entrypoint.sh zkSer"   5 months ago        Exited (0) 50 minutes ago                         db61a2f2-9b47-4d97-97a3-b6e0764208ca
d72c359c2d5e        192.168.0.34:5000/mysql:5.6.30                "docker-entrypoint.sh"   5 months ago        Exited (0) 50 minutes ago                         c7638fa0-f263-45bd-85d7-2e3b7407ad2f
0c8d3edbc53d        rancher/agent-instance:v0.8.3                 "/etc/init.d/agent-in"   5 months ago        Exited (128) 50 minutes ago                       e505b911-a391-4d1c-8ef2-7bbb306df8eb
be4238200956        rancher/agent:v1.0.2                          "/run.sh run"            5 months ago        Up 11 minutes                                     rancher-agent
```

发现服务全都是`Exited`状态，`Rancher`控制台上`Network Agent`容器也是一直转圈圈`Restarting`状态。

因此断定应该是`Network Agent`服务没有启动导致的所有服务无法恢复自动启动。

那为什么会出现这个问题？这个问题是什么原因导致的呢？

在解决这个问题之前先看一下`Rancher`的网络+负载均衡 实现与说明

# Rancher网络+负载均衡的实现与说明

依赖镜像：`rancher/agent-instance:v0.8.3`

`Rancher`网络是采用SDN技术所建容器为虚拟ip地址，各host之间容器采用ipsec隧道实现跨主机通信，使用的是udp的500和4500端口。

启动任务时，在各个host部署容器之前会起一个`Network  Agent`容器，负责组建网络环境。

网络全都靠`agent-instance`容器实现，网络没有准备好其余的容器当然也不会自动恢复。

那我们的这个问题就是`agent-instance`容器没有起来导致的，那让我们启动`agent-instance`容器。

```
docker@xxx:~$ docker start 0c8d3edbc53d
Error response from daemon: rpc error: code = 2 desc = "oci runtime error: exec format error"
Error: failed to start containers: 0c8d3edbc53d
```

很遗憾提示错误无法启动，那让我们看一下日志中的错误是什么？

```
docker@xxx:~$ docker logs --tail=200 -f 0c8d3edbc53d
.......省略其他的
INFO: Sending agent-instance-startup applied 3-0f669dbfe83bbb7389a0c2129247f633575904e41d665e311051de2ce1b85737
Starting monit daemon with http interface at [localhost:2812]
The system is going down NOW!
Sent SIGTERM to all processes
Sent SIGKILL to all processes
Requesting system reboot
INFO: Downloading agent http://192.168.0.34:8080/v1/configcontent/configscripts
```

发现`The system is going down NOW!`这个错误，什么情况？无法启动要求重启系统。

于是查看`rancher`官方相关这个问题的issues，也没看出个所以然来，跟我的系统版本和agent、agent-instance版本都一致也有很多人无法启动或者启动报错。

* [agent-instance cannot start automatically on Ubuntu 16.04.X #5951](https://github.com/rancher/rancher/issues/5951)
* [Rancher network agent stuck in restart loop - DNS lookup issue #4237](https://github.com/rancher/rancher/issues/4237)


最终无解尝试暴力做法，删除以前的agent-instance容器，然后重新创建重启

删除rancher/agent-instance:v0.8.3容器

```
docker@xxx:~$ docker rm 0c8d3edbc53d
0c8d3edbc53d
```

查看有没有rancher/agent-instance:v0.8.3这个镜像

```
docker@xxx:~$ docker images
REPOSITORY                             TAG                 IMAGE ID            CREATED             SIZE
192.168.0.34:5000/saas-erp             latest              0ad78488245a        4 days ago          275.4 MB
192.168.0.34:5000/tms2job              latest              caa888ff603f        4 weeks ago         236.8 MB
192.168.0.34:5000/customer-mq          latest              db319e29bd7f        8 weeks ago         431.8 MB
192.168.0.34:5000/saas-account         latest              004999746d2c        9 weeks ago         181.9 MB
192.168.0.34:5000/saas-erp-http-main   latest              9a5f8be5ef8d        4 months ago        200.8 MB
192.168.0.34:5000/messer               1.0                 74e9ec4742cc        7 months ago        184.8 MB
192.168.0.34:5000/tomcat               7                   830387a4274c        19 months ago       357.8 MB
rancher/agent-instance                 v0.8.3              b6b013f2aa85        20 months ago       331 MB
192.168.0.34:5000/rancher/agent        v1.0.2              860ed2b2e8e3        20 months ago       454.3 MB
rancher/agent                          v1.0.2              860ed2b2e8e3        20 months ago       454.3 MB
192.168.0.34:5000/mysql                5.6.30              2c0964ec182a        21 months ago       329 MB
192.168.0.34:5000/zookeeper            elevy               d2805d0326a9        2 years ago         131.8 MB
```

有镜像，根据镜像重新创建rancher/agent-instance:v0.8.3容器

```
docker@xxx:~$ docker run -d b6b013f2aa85
0060edfa2594
```

<span style="color:blue">*ps.-d, --detach                    Run container in background and print container ID，后台运行容器并且打印出容器ID*</span>

OK创建好了，再ps查看一下其余的容器是否都自动恢复了

```
docker@xxx:~$ docker ps
CONTAINER ID        IMAGE                                         COMMAND                  CREATED             STATUS              PORTS                                                  NAMES
854fa1039e76        192.168.0.34:5000/zookeeper:elevy             "/entrypoint.sh zkSer"   33 minutes ago      Up 33 minutes       2888/tcp, 3888/tcp, 0.0.0.0:2181->2181/tcp, 9010/tcp   r-zookeeper_zookeeper-2_1
47c189dbd5c6        b6b013f2aa85                                  "/etc/init.d/agent-in"   37 minutes ago      Up 37 minutes                                                              drunk_tesla
0060edfa2594        rancher/agent-instance:v0.8.3                 "/etc/init.d/agent-in"   37 minutes ago      Up 37 minutes       0.0.0.0:500->500/udp, 0.0.0.0:4500->4500/udp           e505b911-a391-4d1c-8ef2-7bbb306df8eb
d9da7f16ef2d        192.168.0.34:5000/saas-erp:latest             "./entrypoint.sh"        4 days ago          Up 37 minutes       0.0.0.0:20833->20833/tcp                               r-erp_erp-dubbo_1
79e8e475db19        192.168.0.34:5000/tms2job:latest              "./entrypoint.sh"        4 weeks ago         Up 37 minutes       0.0.0.0:50831->50831/tcp                               r-tms_tms2-job_1
65492930b132        192.168.0.34:5000/saas-account:latest         "./entrypoint.sh"        9 weeks ago         Up 37 minutes       0.0.0.0:20834->20834/tcp                               r-account_account-dubbo_1
248514cd635a        192.168.0.34:5000/saas-erp-http-main:latest   "./entrypoint.sh"        4 months ago        Up 37 minutes       0.0.0.0:20902->20902/tcp                               r-erp_erp-http-main_1
d72c359c2d5e        192.168.0.34:5000/mysql:5.6.30                "docker-entrypoint.sh"   5 months ago        Up 37 minutes       0.0.0.0:3306->3306/tcp                                 c7638fa0-f263-45bd-85d7-2e3b7407ad2f
be4238200956        rancher/agent:v1.0.2                          "/run.sh run"            5 months ago        Up About an hour                                                           rancher-agent
```

很好全都恢复了，Status全都是Up。早知道删除重建就不需要这么麻烦去Issues中找答案，以后记住了只要Network  Agent容器（rancher/agent-instance:v0.8.3）出问题先尝试start，如果无法start就删除了重新创建容器。

