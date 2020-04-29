---
toc : true
title : "Spring Cloud Netflix架构浅析"
zhuan : true
description : "Spring Cloud Netflix架构浅析"
tags : [
	"spring cloud",
	"netflix",
	"hystrix",
	"Eureka",
	"zuul",
	"ribbon",
	"ucm",
	"rpc",
	"devops",
	"monitor"

]
date : "2017-12-25 13:58:36"
categories : [
    "spring cloud",
	"netflix"
]
menu : "main"
---


# 点评

这篇文章比较适合入门，对于spring cloud生态的成员有一个大致的了解，其实spring cloud生态将netflix的产品进行了很好的整合，netflix早几年就在服务治理这块有很深入的研究，出品了很多服务治理的工具hystrix就是很有名的一个，具体可以查看：[https://github.com/netflix](https://github.com/netflix)，刚好在微服务盛行的年代服务治理是必不可少的一环，现在在微服务开发套件这块常用也就是下面这两种选择：

1. spring cloud套件，成熟上手快
2. 自建微服务架构
	1. UCM，统一配置管理（百度的disconf、阿里的diamond、点评的lion，等很多开源的）。
	2. RPC，阿里的Dubbo、点评的Pigeon，当当改的DubboX，grpc，等等很多开源的，还有很多公司自研的。
	3. 服务治理，netflix的hystrix老牌的功能强大的服务治理工具，有熔断、降级等功能，很多公司会结合监控套件开发自己的服务治理工具。
	4. 开发框架（rpc、restful这个一般公司都有自研的开发框架）
	5. 注册中心（zookeeper、redis、Consul、SmartStack、Eureka，其中一些已经是spring cloud生态的一员了）。
	6. 网关，restful的使用nginx+lua，这也是openAPI网关常用的手段
	7. 负载均衡，这个结合选用的rpc框架来选择。一般rpc框架都有负载均衡的功能。
	7. 服务治理熔断，使用hystrix（也已经是spring cloud生态的一员了）
	8. 监控，使用pinpoint、点评的cat、等其他开源的APM工具
	9. DevOPS，持续交付一般也是自己构架的，采用jenkins打包docker镜像，使用docker生态的工具构建容器化发布平台。


下面文章转自：https://my.oschina.net/u/3747963/blog/1592777
作者：@海岸线的曙光

#  微服务框架Spring Boot+Spring Cloud 

Spring Cloud是基于[Spring Boot](http://www.60kb.com/tags-11.html)的一整套实现[微服务](http://www.60kb.com/tags-20.html)的框架，可以说，Spring Boot作为框架，Spring Cloud作为微服务，一起构成了一种不可忽视的、新生的框架体系。它提供了微服务开发所需的配置管理、服务发现、断路器、智能路由、微代理、控制总线、全局锁、决策竞选、[分布式](http://www.60kb.com/tags-16.html)会话和集群状态管理等组件，方便易用。Spring Cloud包含了非常多的子框架，其中，Spring Cloud [Netflix](http://www.60kb.com/tags-29.html)是其中一套框架，它主要提供的模块包括：服务发现、断路器和监控、智能路由、客户端负载均衡等。

# Spring Cloud Netflix组件以及部署

1. Eureka，服务注册和发现，它提供了一个服务注册中心、服务发现的客户端，还有一个方便的查看所有注册的服务的界面。 所有的服务使用Eureka的服务发现客户端来将自己注册到Eureka的服务器上。
2. [Zuul](http://www.60kb.com/tags-63.html)，网关，所有的客户端请求通过这个网关访问后台的服务。他可以使用一定的路由配置来判断某一个URL由哪个服务来处理。并从Eureka获取注册的服务来转发请求。
3. [Ribbon](http://www.60kb.com/tags-55.html)，即负载均衡，Zuul网关将一个请求发送给某一个服务的应用的时候，如果一个服务启动了多个实例，就会通过Ribbon来通过一定的负载均衡策略来发送给某一个服务实例。
4. Feign，服务客户端，服务之间如果需要相互访问，可以使用RestTemplate，也可以使用Feign客户端访问。它默认会使用Ribbon来实现负载均衡。
5. Hystrix，监控和断路器。我们只需要在服务接口上添加Hystrix标签，就可以实现对这个接口的监控和断路器功能。
6. Hystrix Dashboard，监控面板，他提供了一个界面，可以监控各个服务上的服务调用所消耗的时间等。
7. Turbine，监控聚合，使用Hystrix监控，我们需要打开每一个服务实例的监控信息来查看。而Turbine可以帮助我们把所有的服务实例的监控信息聚合到一个地方统一查看。

# Spring Cloud Netflix组件开发

可以参考其中文文档：[https://springcloud.cc/spring-cloud-netflix.html](https://springcloud.cc/spring-cloud-netflix.html)

* 服务注册与监控中心：

```
@SpringBootApplication
@EnableEurekaServer
@EnableHystrixDashboard
public class ApplicationRegistry {
    public static void main(String[] args) {
        new SpringApplicationBuilder(Application.class).web(true).run(args);
    }
}
```

这里使用spring boot标签的 @SpringBootApplication 说明当前的应用是一个spring boot应用。这样我就可以直接用main函数在IDE里面启动这个应用，也可以打包后用命令行启动。当然也可以把打包的war包用tomcat之类的服务器启动。 使用标签 @EnableEurekaServer ，就能在启动过程中启动Eureka服务注册中心的组件。它会监听一个端口，默认是8761，来接收服务注册。并提供一个web页面，打开以后，可以看到注册的服务。 添加 @EnableHystrixDashboard 就会提供一个监控的页面，我们可以在上面输入要监控的服务的地址，就可以查看启用了Hystrix监控的接口的调用情况。 当然，为了使用上面的组件，我们需要在maven的POM文件里添加相应的依赖，比如使用 spring-boot-starter-parent ，依赖 spring-cloud-starter-eureka-server 和 spring-cloud-starter-hystrix-dashboard 等。

* 服务间调用：

两种方式可以进行服务调用，RestTemplate和FeignClient。不管是什么方式，他都是通过REST接口调用服务的http接口，参数和结果默认都是通过jackson序列化和反序列化。因为Spring MVC的RestController定义的接口，返回的数据都是通过jackson序列化成json数据。

第一种：RestTemplate，只需要定义一个RestTemplate的Bean，设置成 LoadBalanced 即可：

```
@Configuration
public class SomeCloudConfiguration {
    @LoadBalanced
    @Bean
    RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

这样我们就可以在需要用的地方注入这个bean使用：

```
public class SomeServiceClass {
    @Autowired
    private RestTemplate restTemplate;
    public String getUserById(Long userId) {
        UserDTO results = restTemplate.getForObject("http://users/getUserDetail/" + userId, UserDTO.class);
        return results;
    }
}
```

其中， users 是服务ID，Ribbon会从服务实例列表获得这个服务的一个实例，发送请求，并获得结果。对象 UserDTO 需要序列号，它的反序列号会自动完成。

第二种：FeignClient

```
@FeignClient(value = "users", path = "/users")
public interface UserCompositeService {
    @RequestMapping(value = "/getUserDetail/{id}", method = RequestMethod.GET, produces = MediaType.APPLICATION_JSON_VALUE)
    UserDTO getUserById(@PathVariable Long id);
}
```

我们只需要使用 @FeignClient 定义一个借口，Spring Cloud Feign会帮我们生成一个它的实现，从相应的users服务获取数据。 其中， @FeignClient(value = "users", path = "/users/getUserDetail") 里面的value是服务ID，path是这一组接口的path前缀。 在下面的方法定义里，就好像设置Spring MVC的接口一样，对于这个方法，它对应的URL是 /users/getUserDetail/{id} 。 然后，在使用它的时候，就像注入一个一般的服务一样注入后使用即可：

```
public class SomeOtherServiceClass {
    @Autowired
    private UserCompositeService userService;
    public void doSomething() {
        // .....                    
        UserDTO results = userService.getUserById(userId);
        // other operation...                    
    }
}
```

* 断路器：

```
//断路器：为了解决当某个方法调用失败的时候，调用后备方法来替代失败的方法，已达到容错／阻止级联错误的功能
//fallbackMethod指定后备方法
@HystrixCommand(fallbackMethod = "doStudentFallback")
@RequestMapping(value = "dostudent",method = RequestMethod.GET)
public String doStudent(){
   return "your name:secret,your age:secret!";
}

public String doStudentFallback(){
   return "your name:FEIFEI,your age:26!";
}
```

其中，使用@EnableCircuitBreaker来启用断路器支持，Spring Cloud提供了一个控制台来监控断路器的运行情况，通过@EnableHystrixDashboard注解开启。

以上是简单的一些对Spring Cloud Netflix组件的介绍。