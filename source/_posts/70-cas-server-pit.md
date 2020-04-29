---
toc : true
title : "Trouble Shooting —— CAS Server集群环境下TGC验证问题排查，需要开启会话保持"
description : "Trouble Shooting —— CAS Server集群环境下TGC验证问题排查，需要开启会话保持"
tags : [
	"CAS",
	"trouble shooting",
	"iphash",
	"TomcatRedisSessionManager",
	"Invalid cookie. Required remote address does not match ip"
]
date : "2018-03-16 12:02:53"
categories : [
    "CAS"
]
menu : "main"
---


# 问题现象

`CAS`部署结构：

两台`cas server`通过`nginx`做负载均衡，两个`cas server`的`ticket registry`配置的`jpa`方式，指向同一个库。两个`cas server`的`tomcat`做了`TomcatRedisSessionManager`，使用`redis`集中存储`session`。

目前的现象：

页面上请求`cas`登录地址，登录过后频繁刷新登录页面，有时返回已登录，有时返回未登录，当返回未登录时去后台查看日志发现有如下错误，验证`cookie`发现请求的源`IP`与第一次访问的源`IP`不一致。这个很明显是`cas`集群环境下的问题。

```
2018-03-16 10:02:44,418 DEBUG [org.apereo.cas.web.support.TGCCookieRetrievingCookieGenerator] - <Invalid cookie. Required remote address does not match ${ip}>
java.lang.IllegalStateException: Invalid cookie. Required remote address does not match ${ip}
	at org.apereo.cas.web.support.DefaultCasCookieValueManager.obtainCookieValue(DefaultCasCookieValueManager.java:84) ~[cas-server-support-cookie-5.0.4.jar:5.0.4]
	at org.apereo.cas.web.support.CookieRetrievingCookieGenerator.retrieveCookieValue(CookieRetrievingCookieGenerator.java:93) ~[cas-server-support-cookie-5.0.4.jar:5.0.4]
	at org.apereo.cas.web.support.CookieRetrievingCookieGenerator$$FastClassBySpringCGLIB$$25dba342.invoke(<generated>) ~[cas-server-support-cookie-5.0.4.jar:5.0.4]
	at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204) ~[spring-core-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.invokeJoinpoint(CglibAopProxy.java:720) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:157) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.support.DelegatingIntroductionInterceptor.doProceed(DelegatingIntroductionInterceptor.java:133) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.support.DelegatingIntroductionInterceptor.invoke(DelegatingIntroductionInterceptor.java:121) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:655) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apereo.cas.web.support.CookieRetrievingCookieGenerator$$EnhancerBySpringCGLIB$$10d36968.retrieveCookieValue(<generated>) ~[cas-server-support-cookie-5.0.4.jar:5.0.4]
	at org.apereo.cas.logging.web.ThreadContextMDCServletFilter.doFilter(ThreadContextMDCServletFilter.java:83) ~[cas-server-core-logging-5.0.4.jar:5.0.4]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.springframework.web.filter.RequestContextFilter.doFilterInternal(RequestContextFilter.java:99) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.springframework.web.filter.HttpPutFormContentFilter.doFilterInternal(HttpPutFormContentFilter.java:89) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.springframework.web.filter.HiddenHttpMethodFilter.doFilterInternal(HiddenHttpMethodFilter.java:77) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.springframework.boot.actuate.autoconfigure.MetricsFilter.doFilterInternal(MetricsFilter.java:107) ~[spring-boot-actuator-1.4.2.RELEASE.jar:1.4.2.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:197) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.springframework.boot.web.support.ErrorPageFilter.doFilter(ErrorPageFilter.java:117) ~[spring-boot-1.4.2.RELEASE.jar:1.4.2.RELEASE]
	at org.springframework.boot.web.support.ErrorPageFilter.access$000(ErrorPageFilter.java:61) ~[spring-boot-1.4.2.RELEASE.jar:1.4.2.RELEASE]
	at org.springframework.boot.web.support.ErrorPageFilter$1.doFilterInternal(ErrorPageFilter.java:92) ~[spring-boot-1.4.2.RELEASE.jar:1.4.2.RELEASE]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:107) ~[spring-web-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.boot.web.support.ErrorPageFilter.doFilter(ErrorPageFilter.java:110) ~[spring-boot-1.4.2.RELEASE.jar:1.4.2.RELEASE]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.apache.logging.log4j.web.Log4jServletFilter.doFilter(Log4jServletFilter.java:71) ~[log4j-web-2.6.2.jar:2.6.2]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:241) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:208) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:219) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:110) ~[catalina.jar:7.0.85]
	at com.r.tomcat.session.management.RequestSessionHandlerValve.invoke(RequestSessionHandlerValve.java:30) ~[TomcatRedisSessionManager-1.0.jar:?]
	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:169) ~[catalina.jar:7.0.85]
	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:103) ~[catalina.jar:7.0.85]
	at org.apache.catalina.valves.AccessLogValve.invoke(AccessLogValve.java:962) ~[catalina.jar:7.0.85]
	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:116) ~[catalina.jar:7.0.85]
	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:445) ~[catalina.jar:7.0.85]
	at org.apache.coyote.http11.AbstractHttp11Processor.process(AbstractHttp11Processor.java:1115) ~[tomcat-coyote.jar:7.0.85]
	at org.apache.coyote.AbstractProtocol$AbstractConnectionHandler.process(AbstractProtocol.java:637) ~[tomcat-coyote.jar:7.0.85]
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1775) ~[tomcat-coyote.jar:7.0.85]
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.run(NioEndpoint.java:1734) ~[tomcat-coyote.jar:7.0.85]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) [?:1.8.0_162]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) [?:1.8.0_162]
	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) ~[tomcat-coyote.jar:7.0.85]
	at java.lang.Thread.run(Thread.java:748) [?:1.8.0_162]

```

网上查询资料：[google group](https://groups.google.com/a/apereo.org/forum/#!topic/cas-user/R4WVT4Tq0g8)，相同的问题，但是没有看到具体的解决方法。

看到的[tomcat RemoteIpValue](https://tomcat.apache.org/tomcat-7.0-doc/api/org/apache/catalina/valves/RemoteIpValve.html)也只是`tomcat`请求`ip`限制的方法，跟我们要的不匹配

根据异常查看`CAS`代码，如下：

```
 public String obtainCookieValue(Cookie cookie, HttpServletRequest request)
  {
    String cookieValue = (String)this.cipherExecutor.decode(cookie.getValue());
    LOGGER.debug("Decoded cookie value is [{}]", cookieValue);
    if (StringUtils.isBlank(cookieValue))
    {
      LOGGER.debug("Retrieved decoded cookie value is blank. Failed to decode cookie [{}]", cookie.getName());
      return null;
    }
    String[] cookieParts = cookieValue.split(String.valueOf('@'));
    if (cookieParts.length != 3) {
      throw new IllegalStateException("Invalid cookie. Required fields are missing");
    }
    String value = cookieParts[0];
    String remoteAddr = cookieParts[1];
    String userAgent = cookieParts[2];
    if ((StringUtils.isBlank(value)) || (StringUtils.isBlank(remoteAddr)) || 
      (StringUtils.isBlank(userAgent))) {
      throw new IllegalStateException("Invalid cookie. Required fields are empty");
    }
    if (!remoteAddr.equals(request.getRemoteAddr())) {
      throw new IllegalStateException("Invalid cookie. Required remote address does not match " + request.getRemoteAddr());
    }
    String agent = WebUtils.getHttpServletRequestUserAgent(request);
    if (!userAgent.equals(agent)) {
      throw new IllegalStateException("Invalid cookie. Required user-agent does not match " + agent);
    }
    return value;
  }
```

`TGC`中包含了`user-agent`信息，会根据`request`的`user-agent`去跟`decode`后的`cookie`中的`user-agent`对比，而且这个验证是在`cas 4.1`版本就已经加了这个验证信息了，如果我们修改源码去掉这个`user-agent`验证可能还会引发其他问题。

# 解决方案



采用负载均衡的粘性配置，nginx中可以是ip_hash或者sticky。

1. 如果使用的是阿里云的`SLB`需要开启会话保持的选项。
2. 如果使用`nginx`需要在`upstream`中增加`ip_hash`保持会话。

<span style="color:blue">*这样就可以让相同的客户端ip将会话永远路由到相同的一台后端`cas server`上去。*</span>



现在不建议使用上面的方法解决，这个会丢失集群的特性，建议采用配置来关闭cas.tgc的加解密或者修改cas源代码解决问题，查看这篇文章[《Trouble Shooting —— CAS Server集群环境下TGC验证问题》](https://ningyu1.github.io/blog/20191015/118-cas-server-pit.htmll)中的解决办法



经过验证解决了上述的问题。

所以这里需要说明一下，在对`cas server`做集群实现无状态化，需要注意一下几点：

1. `cas`的`ticket`需要做到集中存储，可以使用`redis`、`jpa`、或者其他方式，这个官方文章上有详细介绍：[ticket-registry](https://apereo.github.io/cas/5.0.x/installation/Configuration-Properties.html#ticket-registry)
2. `cas`的`session`信息需要做到集中存储，如果使用的是`tomcat`可以使用[TomcatRedisSessionMananger](https://github.com/ran-jit/tomcat-cluster-redis-session-manager)插件来通过redis做session集中存储。
3. 需解决集群环境和springwebflow框架下CAS登录流程数据加密秘钥统一（或去除登录流程数据加密）-> cas.webflow.encryption.key，cas.webflow.signing.key
4. 需解决集群环境和springwebflow框架下CAS登录票据加密秘钥统一（或去除票据数据加密）-> cas.tgc.cipherEnabled，cas.tgc.signingKey，cas.tgc.encryptionKey
5. 最后一个就是需要接入`sso`的`client`应用端的`session`信息也需要做集中存储，因此`cas server`会和`client`进行通信去验证`ticket`，验证完后会生成信息并存储到`sesson`中，因此也需要使用[TomcatRedisSessionMananger](https://github.com/ran-jit/tomcat-cluster-redis-session-manager)插件来通过`redis`做`session`集中存储。

世界和平、Keep Real！