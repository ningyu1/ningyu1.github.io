---
toc : true
title : "Trouble Shooting —— CAS Server集群环境下报错：Server redirected too many  times (20)"
description : "Trouble Shooting —— CAS Server集群环境下报错：Server redirected too many  times (20)"
tags : [
	"CAS",
	"trouble shooting",
	"iphash",
	"TomcatRedisSessionManager",
	"Server redirected too many  times (20)"
]
date : "2018-03-23 16:01:00"
categories : [
    "CAS"
]
menu : "main"
---

当我们使用`cas`做单点登录的时候往往会使用集群方式部署，不管是`cas server`或者是接入的`app server`都会采用集群的方式部署。

在对`cas server`做集群实现无状态化，需要注意一下几点，也是我上一篇`cas`遇到的`TGC`验证问题中总结出来的：

1. `cas`的`ticket`需要做到集中存储，可以使用`redis`、`jpa`、或者其他方式，这个官方文章上有详细介绍：[ticket-registry](https://apereo.github.io/cas/5.0.x/installation/Configuration-Properties.html#ticket-registry)
2. `cas`的`session`信息需要做到集中存储，如果使用的是`tomcat`可以使用[TomcatRedisSessionMananger](https://github.com/ran-jit/tomcat-cluster-redis-session-manager)插件来通过`redis`做`session`集中存储。
3. 还有一个就是上面遇到的问题，客户端`cookie`信息：`TGC`，`TGC`采用`cookie`方式存在客户端，因此需要开启会话保持，使得相同客户端每次都会被路由到同一个`cas server`上去做`TGC`验证。
4. 最后一个就是需要接入`sso`的`client`应用端的`session`信息也需要做集中存储，因此`cas server`会和`client`进行通信去验证`ticket`，验证完后会生成信息并存储到`sesson`中，因此也需要使用[TomcatRedisSessionMananger](https://github.com/ran-jit/tomcat-cluster-redis-session-manager)插件来通过`redis`做`session`集中存储。
5. cas server端和接入的app服务端需要保证网络通畅。

# cas使用总结博文目录

最近`cas`遇到的问题我都总结到了blog中，这里整理一下目录如下：

* [《CAS使用经验总结，纯干货》](https://ningyu1.github.io/site/post/54-cas-server/)
* [《CAS Server强制踢人功能实现方式》](https://ningyu1.github.io/site/post/57-cas-server1/)
* [《Trouble Shooting —— CAS Server集群环境下TGC验证问题排查，需要开启会话保持》](https://ningyu1.github.io/site/post/70-cas-server-pit/)


接下来我们就说一下这次遇到的问题。

# 问题现象

通过上面的方式可以将`cas server`做到集群无状态化，但是避免不了其他的问题，下面就是最近与到的问题，现象是这样的，一部分人可以正常登陆，一部分人登陆时报错，错误如下：

```
2018-03-23 10:33:22.768 [http-nio-7051-exec-1] ERROR org.jasig.cas.client.util.CommonUtils - Server redirected too many  times (20)
java.net.ProtocolException: Server redirected too many  times (20)
	at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1637) ~[na:1.7.0_79]
	at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:254) ~[na:1.7.0_79]
	at org.jasig.cas.client.util.CommonUtils.getResponseFromServer(CommonUtils.java:393) ~[cas-client-core-3.3.3.jar:3.3.3]
	at org.jasig.cas.client.validation.AbstractCasProtocolUrlBasedTicketValidator.retrieveResponseFromServer(AbstractCasProtocolUrlBasedTicketValidator.java:45) [cas-client-core-3.3.3.jar:3.3.3]
	at org.jasig.cas.client.validation.AbstractUrlBasedTicketValidator.validate(AbstractUrlBasedTicketValidator.java:200) [cas-client-core-3.3.3.jar:3.3.3]
	at org.springframework.security.cas.authentication.CasAuthenticationProvider.authenticateNow(CasAuthenticationProvider.java:140) [spring-security-cas-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.cas.authentication.CasAuthenticationProvider.authenticate(CasAuthenticationProvider.java:126) [spring-security-cas-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.authentication.ProviderManager.authenticate(ProviderManager.java:156) [spring-security-core-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.cas.web.CasAuthenticationFilter.attemptAuthentication(CasAuthenticationFilter.java:242) [spring-security-cas-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.authentication.AbstractAuthenticationProcessingFilter.doFilter(AbstractAuthenticationProcessingFilter.java:195) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.jasig.cas.client.session.SingleSignOutFilter.doFilter(SingleSignOutFilter.java:100) [cas-client-core-3.3.3.jar:3.3.3]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at com.bstek.bdf2.core.security.filter.PreAuthenticatedProcessingFilter.doFilter(PreAuthenticatedProcessingFilter.java:41) [scm-bdf2-core-1.1.0-SNAPSHOT.jar:na]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.authentication.logout.LogoutFilter.doFilter(LogoutFilter.java:105) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.session.ConcurrentSessionFilter.doFilter(ConcurrentSessionFilter.java:125) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at com.bstek.bdf2.core.security.filter.ContextFilter.doFilter(ContextFilter.java:36) [scm-bdf2-core-1.1.0-SNAPSHOT.jar:na]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.context.SecurityContextPersistenceFilter.doFilter(SecurityContextPersistenceFilter.java:87) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:342) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.FilterChainProxy.doFilterInternal(FilterChainProxy.java:192) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.security.web.FilterChainProxy.doFilter(FilterChainProxy.java:160) [spring-security-web-3.1.7.RELEASE.jar:3.1.7.RELEASE]
	at org.springframework.web.filter.DelegatingFilterProxy.invokeDelegate(DelegatingFilterProxy.java:344) [spring-web-4.0.0.RELEASE.jar:4.0.0.RELEASE]
	at org.springframework.web.filter.DelegatingFilterProxy.doFilter(DelegatingFilterProxy.java:261) [spring-web-4.0.0.RELEASE.jar:4.0.0.RELEASE]
```

从异常的描述来看是服务器端多次`redirected`超过了20次导致的问题，什么原因会造成这个问题？

# cas单点登录过程剖析

`cas`的单点登录的过程大致是这样的。

第一步：访问app地址，例如：`https://app.domain.com`，app端的`cas-client-core`会判断是否已经登录，如果没有登录会重定向到如下地址：`https://login.domain.com/login?service=https%3A%2F%2Fapp.domain.com%2Fcas_security_check_`

第二步：当重定向到`cas`登录页面后，我们输入用户名密码，`cas server`端会进行如下操作

* 先进行`AUTHENTICATION`过程，这个过程是验证我们的用户名密码是否正确，会输出如下日志：

```
2018-03-23 14:58:01,429 INFO [org.apereo.inspektr.audit.support.Slf4jLoggingAuditTrailManager] - <Audit trail record BEGIN
=============================================================
WHO: admin
WHAT: Supplied credentials: [admin]
ACTION: AUTHENTICATION_SUCCESS
APPLICATION: CAS
WHEN: Fri Mar 23 14:58:01 HKT 2018
CLIENT IP ADDRESS: xx.xx.xx.xx
SERVER IP ADDRESS: xx.xx.xx.xx
=============================================================
```

* 当`AUTHENTICATION`通过以后会生成TGT（TICKET_GRANTING_TICKET），这个是换取服务票据的预授票据，并且将TGT保存起来，我这里使用的是jpa方式保存到db，会输出如下日志：

```
=============================================================
WHO: admin
WHAT: TGT-***********************************************1VX72iaQBZ-077adac8d80f
ACTION: TICKET_GRANTING_TICKET_CREATED
APPLICATION: CAS
WHEN: Fri Mar 23 14:58:01 HKT 2018
CLIENT IP ADDRESS: 10.42.37.135
SERVER IP ADDRESS: 10.42.185.88
=============================================================

>
Hibernate: insert into TICKETGRANTINGTICKET (NUMBER_OF_TIMES_USED, CREATION_TIME, EXPIRATION_POLICY, LAST_TIME_USED, PREVIOUS_LAST_TIME_USED, AUTHENTICATION, EXPIRED, PROXIED_BY, SERVICES_GRANTED_ACCESS_TO, ticketGrantingTicket_ID, TYPE, ID) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'TGT', ?)
```

* 当`TGT`生成完后会生成ST（SERVICE_TICKET），这个是服务票据，是授权这个服务的票据，并且会将ST保存起来和更新TGT信息，我这里使用的是jpa方式保存到db，会输出如下日志：

```
2018-03-23 14:58:01,504 INFO [org.apereo.inspektr.audit.support.Slf4jLoggingAuditTrailManager] - <Audit trail record BEGIN
=============================================================
WHO: admin
WHAT: ST-153-RfpK0ACJHtPsSdnbYhVf-077adac8d80f for https://app.domain.com/cas_security_check_
ACTION: SERVICE_TICKET_CREATED
APPLICATION: CAS
WHEN: Fri Mar 23 14:58:01 HKT 2018
CLIENT IP ADDRESS: xx.xx.xx.xx
SERVER IP ADDRESS: xx.xx.xx.xx
=============================================================

>
Hibernate: insert into SERVICETICKET (NUMBER_OF_TIMES_USED, CREATION_TIME, EXPIRATION_POLICY, LAST_TIME_USED, PREVIOUS_LAST_TIME_USED, FROM_NEW_LOGIN, TICKET_ALREADY_GRANTED, SERVICE, ticketGrantingTicket_ID, TYPE, ID) values (?, ?, ?, ?, ?, ?, ?, ?, ?, 'ST', ?)
Hibernate: update TICKETGRANTINGTICKET set NUMBER_OF_TIMES_USED=?, CREATION_TIME=?, EXPIRATION_POLICY=?, LAST_TIME_USED=?, PREVIOUS_LAST_TIME_USED=?, AUTHENTICATION=?, EXPIRED=?, PROXIED_BY=?, SERVICES_GRANTED_ACCESS_TO=?, ticketGrantingTicket_ID=? where ID=?
```

这个时候服务端生成的票据就完成了，会将ST信息生成TGC（TICKET_GRANTING_COOKIE）返回给app端。

第三步：app端接收到cas server端的返回，TGC会直接写入到浏览器cookie中，app端会再发起一次ST验证，这个过程是在app的后端发起请求的，url如下：

`https://login.domain.com/serviceValidate?ticket=ST-153-RfpK0ACJHtPsSdnbYhVf-077adac8d80f&service=https%3A%2F%2Fapp.domain.com%2Fcas_security_check_`

第四步：cas server端收到service validate请求后会验证ST和TGC是否合法，并且验证TGC的时候cas server需要开启会话保持，让请求发送到生成TGC的机器上去，因为TGC中保存生成的服务端地址，具体问题我前面分析过查看：[《Trouble Shooting —— CAS Server集群环境下TGC验证问题排查，需要开启会话保持》](https://ningyu1.github.io/site/post/70-cas-server-pit/)，cas server验证成功后会输出如下的日志：

```
2018-03-23 14:58:01,578 INFO [org.apereo.inspektr.audit.support.Slf4jLoggingAuditTrailManager] - <Audit trail record BEGIN
=============================================================
WHO: admin
WHAT: ST-153-RfpK0ACJHtPsSdnbYhVf-077adac8d80f
ACTION: SERVICE_TICKET_VALIDATED
APPLICATION: CAS
WHEN: Fri Mar 23 14:58:01 HKT 2018
CLIENT IP ADDRESS: xx.xx.xx.xx
SERVER IP ADDRESS: xx.xx.xx.xx
=============================================================
```

<span style="color:red">*ps.出现下面日志表示验证失败*</span>

```
2018-03-23 14:58:01,580 INFO [org.apereo.inspektr.audit.support.Slf4jLoggingAuditTrailManager] - <Audit trail record BEGIN
=============================================================
WHO: audit:unknown
WHAT: ST-154-YA6KibaqHpOMGXbluz7V-077adac8d80f
ACTION: SERVICE_TICKET_VALIDATE_FAILED
APPLICATION: CAS
WHEN: Fri Mar 23 14:58:01 HKT 2018
CLIENT IP ADDRESS: xx.xx.xx.xx
SERVER IP ADDRESS: xx.xx.xx.xx
=============================================================
```

第五步：app后端接收到cas server端service验证成功的返回后，会生成session并且与TG进行关系绑定，绑定信息会保存起来，<span style="color:blue">*这里需要注意的是如果是集群环境需要保存到redis或者其他统一存储的地方。*</span>，app后端接收验证成功后的输出日志如下：

```
2018-03-23 14:58:01.531 [http-apr-8080-exec-1] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Constructing validation url: https://login.domain.com/serviceValidate?ticket=ST-153-RfpK0ACJHtPsSdnbYhVf-077adac8d80f&service=https%3A%2F%2Fapp.domain.com%2Fcas_security_check_
2018-03-23 14:58:01.531 [http-apr-8080-exec-1] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Retrieving response from server.
2018-03-23 14:58:01.602 [http-apr-8080-exec-1] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Server response: <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
    <cas:authenticationSuccess>
        <cas:user>admin</cas:user>
    </cas:authenticationSuccess>
</cas:serviceResponse>
```

<span style="color:blue">*输出以上信息就是验证成功。到这里cas server端的所有验证都完成了。*</span>

<span style="color:red">*ps.出现下面日志表示app后端接收到的是验证失败返回信息*</span>

```
2018-03-23 14:58:02.295 [http-bio-7051-exec-6] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Constructing validation url: https://login.domain.com/serviceValidate?ticket=ST-154-YA6KibaqHpOMGXbluz7V-077adac8d80f&service=https%3A%2F%2Fapp.domain.com%2Fcas_security_check_
2018-03-23 14:58:02.295 [http-bio-7051-exec-6] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Retrieving response from server.
2018-03-23 14:58:02.830 [http-bio-7051-exec-6] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Server response: <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
    <cas:authenticationFailure code="INVALID_TICKET">Ticket &#39;ST-154-YA6KibaqHpOMGXbluz7V-077adac8d80f&#39; not recognized</cas:authenticationFailure>
</cas:serviceResponse>
```

第六步：app端登录成功进入主页面。

根据这个流程我们再来分析上面的异常是那个环节出现了问题。

# 问题分析

首先上面的异常是app的后端出现的异常，app后端发起请求是在cas server生成完ticket之后才发起的，并且发起的是service validate验证请求，这个请求导致重定向超过20次。

而且还有一个重要的信息就是，一部分人可以正常登录，一部分人不能登录，我们部署的结构是2台cas server，2台app服务。

通过日志排查，2台app服务，其中一台没有出现过一场，另外一台爆出异常。这个时候问题已经有些明朗了，当负载均衡路由到出错的这台服务时，后台服务发起service validate验证时出现了问题，那接下来就让我们对比两台服务器上的配置。

我们采用的是阿里云的SLB映射到后台的nginx，app的后台服务要和cas server通信那首先网络需要是通的，理论上网络应该是没问题的，但是为了验证问题，我们就从网络这块开始排查。

因为我们使用的是阿里云而且app服务没有开通外网，app后天和cas服务通信走的是内网的SLB，接下来我们就ping一下登录地址看一下返回的slb地址是否相同。

两台机器上ping login.domain.com ，果然返回的ip不一致，其中报错的那台机器返回的是本机ip，奥这就是问题的根源，`cat /etc/hosts`果然域名映射的ip不一致，应该是运维配置失误导致的问题。

通过修改host配置之后再次验证错误解决。

# 问题总结

最终定位的到的问题感觉很白痴的问题，是因为运维配置失误导致，但是值得回味的是，通过这个问题我们对cas的单点登录机制理解的更加深刻，这就是一种收获，往往通过繁琐的分析后定位到的问题都很easy，所以当我们分析问题、定位问题的时候一定要先理解其中的原理，再结合现象去一步一步分析，这是仔细和关注度是否全面的一种考验。好了问题就说到这里，希望能够帮助到需要的人。

世界和平、Keep Real！