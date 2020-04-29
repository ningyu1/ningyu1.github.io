---
toc : true
title : "CAS使用经验总结，纯干货"
description : "CAS使用经验总结，纯干货"
tags : [
	"CAS",
	"SSL",
	"Cert",
	"SLO",
	"Single Logout",
	"Ticket",
	"Ticket Registry",
	"Session Centralized Storage",
	"Cookie",
	"CAS Cluster",
	"CAS Server"
]
date : "2018-01-19 16:25:36"
categories : [
    "CAS"
]
menu : "main"
---

最近在处理公司项目对接到CAS server，在使用CAS发生了很多问题，下面整理一下遇到的问题与解决方式，希望可以帮助到需要的工程师们

CAS它是什么？它能做什么？这些我就不概述了，自行去搜索了解，[https://baike.baidu.com/item/CAS/1329561](https://baike.baidu.com/item/CAS/1329561)

我们在使用CAS的时候基本都会遇到如下的几种问题：

1. 证书问题
2. Client接入配置
2. SLO（Single Logout）
3. CAS callback回调问题
4. Cookie问题
5. 用户数据源以及认证问题
6. CAS Server Ticket持久化问题
7. Client Server集群模式下session问题

还有一些是公司内部项目框架集成问题这里就不多说了。

**以下总结都是基于CAS v5.0.4版本测试**

我用的CAS Server是通过overlays改造后的项目，为什么需要修改原有的CAS Server呢？

我相信每个公司都有一些特殊的需求比如说：

1. 对登录页面的修改
2. 自有的密码加密验证方式
3. 新老项目架构参差不齐
4. 使用公司自有用户数据源

等等很多问题都需要对CAS Server进行改造

这里我将改造的CAS Server放到github上：

项目地址：[cas-site](https://github.com/ningyu1/cas-site)

<a href="https://github.com/ningyu1/cas-site/releases"><img src="https://img.shields.io/github/release/ningyu1/cas-site.svg?style=social&amp;label=Release"></a>&nbsp;<a href="https://github.com/ningyu1/cas-site/stargazers"><img src="https://img.shields.io/github/stars/ningyu1/cas-site.svg?style=social&amp;label=Star"></a>&nbsp;<a href="https://github.com/ningyu1/cas-site/fork"><img src="https://img.shields.io/github/forks/ningyu1/cas-site.svg?style=social&amp;label=Fork"></a>&nbsp;<a href="https://github.com/ningyu1/cas-site/watchers"><img src="https://img.shields.io/github/watchers/ningyu1/cas-site.svg?style=social&amp;label=Watch"></a> <a href="http://www.gnu.org/licenses/gpl-3.0.html"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg"></a>

下面具体说一下上述的问题将如何来分析并解决

# 证书问题

如果你的服务不打算使用SSL那请跳过这段说明。

一般公司项目会有很多域名大概都是子域名的方式，例如：account.xxxx.com,login.xxxx.com，那么最好使用通配符证书，为什么呢？这样你的cas server上配置一个通配符证书即可，如果没有使用通配符证书那cas server上要配置所有授信域名的证书，这样就很麻烦，除非一些历史问题没办法才会导入多个证书，一般使用通配符证书。

我使用的是自签名的通配符证书，具体自签名证书如何生成可以查看我之前写的文章：

[《Openssl生成自签名证书，简单步骤》](https://ningyu1.github.io/site/post/51-ssl-cert/)中讲述了如何生成自签名证书。

[《使用自签名证书，简单步骤》](https://ningyu1.github.io/site/post/52-ssl-cert-2/)中讲述了如何使用自签名证书。

[《Java访问SSL地址，使用证书方式和免验证证书方式》](https://ningyu1.github.io/site/post/51-ssl-cert-3/)中讲述了Java访问ssl使用证书方式和免验证证书方式。

<span style='color:red'>**ps.这里需要注意的是在制作单域名证书和通配符域名证书的区别是在：Common Name输入的时候，例如：**</span>

单域名证书：`Common Name：account.xxxx.ccom`
通配符域名证书：`Common Name：*.xxxx.com`

将制作好的证书文件通过keytool导入到jdk下即可，或使用InstallCert来生成文件copy到jdk下，具体可以参考文章：[《使用自签名证书，简单步骤》](https://ningyu1.github.io/site/post/52-ssl-cert-2/)

证书放在：`%JAVA_HOME%\jre\lib\security`

我们cas server使用的jdk1.8，client服务大多是jdk1.7，因此在证书处理上要注意这个细节，上面文章中有明确说明

<span style='color:red'>**如果需要使用Docker构建，可以参考我写好的Dockerfile，在cas-site项目下Dockerfile文件**</span>

# Client接入配置

接入cas的client端配置非常简单，可以使用spring framework对接cas方式，也可以使用spring security对接cas方式，或者其他支持cas的第三方框架，自己对接配置非常简单只需要配置`SingleSignOutFilter`和`SingleSignOutHttpSessionListener`

* org.jasig.cas.client.session.SingleSignOutFilter：解决Logout清空TGC和session信息
* org.jasig.cas.client.session.SingleSignOutHttpSessionListener：session监听

这里在对接方面就不做过多的介绍了。

# SLO（Single Logout）

SLO是个什么？

通俗点讲就是：浏览器多个tab页开启不同的APP（使用同一个用户登录），在某一个APP里进行登出操作，其余APP应该一起登出

CAS Server默认是开启SLO功能，如果想要关闭这个功能可以通过设置`application.properties`文件中的参数来关闭，具体如下：

```
# 是否禁用SLO功能，true为禁用SLO功能
cas.slo.disabled=true
# 使用采用异步方式进行callback
cas.slo.asynchronous=true
```

<span style='color:red'>**这里需要注意Logout时服务重定向需要开启：**</span>

```
# Logout时服务重定向
cas.logout.followServiceRedirects=true
```

CAS Server在进行异步回调时会忽略所有的错误来保证所有APP都能接收到Server发出的logout请求，因此在遇到错误时不开启trace级别日志是看不到错误信息的。

如果你的client端能看到接下来的章节（CAS callback回调问题） 说到的日志信息那就证明回调是没有问题的。

# CAS callback回调问题

CAS认证过程需要server端和client端来回调用，如果发现callback回调有问题多半是第一步证书问题导致，可以开启日志trace级别查看cas的日志来排除问题。

cas回调有三种情况:

一个是授权的时候进行回调信息如下

```
2018-01-19 11:44:28.419 [http-apr-8080-exec-9] TRACE org.jasig.cas.client.session.SingleSignOutHandler - Received a token request
2018-01-19 11:44:28.419 [http-apr-8080-exec-9] DEBUG org.jasig.cas.client.session.SingleSignOutHandler - Recording session for token ST-250-AouhaxqAjvmh5sfaP3Yz-8ec54e266608
2018-01-19 11:44:28.419 [http-apr-8080-exec-9] DEBUG c.j.f.c.s.storage.RedisBackedSessionMappingStorage - Attempting to remove Session=[8F24552DD446F669B7A522B1A8A0C86D]
2018-01-19 11:44:28.419 [http-apr-8080-exec-9] DEBUG c.j.f.c.s.storage.RedisBackedSessionMappingStorage - No mapping for session found.  Ignoring.
2018-01-19 11:44:28.420 [http-apr-8080-exec-9] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Placing URL parameters in map.
2018-01-19 11:44:28.420 [http-apr-8080-exec-9] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Calling template URL attribute map.

2018-01-19 11:44:28.420 [http-apr-8080-exec-9] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Loading custom parameters from configuration.
2018-01-19 11:44:28.420 [http-apr-8080-exec-9] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Constructing validation url: https://login.dev.xxx.com.cn/serviceValidate?ticket=ST-250-AouhaxqAjvmh5sfaP3Yz-8ec54e266608&service=https%3A%2F%2Faccount.dev.xxx.com.cn%2Fcas_security_check_
2018-01-19 11:44:28.420 [http-apr-8080-exec-9] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Retrieving response from server.
2018-01-19 11:44:28.460 [http-apr-8080-exec-9] DEBUG o.j.c.c.validation.Cas20ServiceTicketValidator - Server response: <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
    <cas:authenticationSuccess>
        <cas:user>admin</cas:user>
        </cas:authenticationSuccess>
</cas:serviceResponse>

```

一个是SLO时清理session的回调信息如下

```
2018-01-19 11:44:45.484 [http-apr-8080-exec-5] TRACE org.jasig.cas.client.session.SingleSignOutHandler - Received a back channel logout request
2018-01-19 11:44:45.484 [http-apr-8080-exec-5] DEBUG org.jasig.cas.client.util.CommonUtils - safeGetParameter called on a POST HttpServletRequest for Restricted Parameters.  Cannot complete check safely.  Reverting to standard behavior for this Parameter
2018-01-19 11:44:45.485 [http-apr-8080-exec-5] TRACE org.jasig.cas.client.session.SingleSignOutHandler - Logout request:
<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="LR-79-M3OyvVsRH7Ft1gRVaBfeuBCAj4K1JEDnndt" Version="2.0" IssueInstant="2018-01-19T11:44:45Z"><saml:NameID xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">@NOT_USED@</saml:NameID><samlp:SessionIndex>ST-250-AouhaxqAjvmh5sfaP3Yz-8ec54e266608</samlp:SessionIndex></samlp:LogoutRequest>
2018-01-19 11:44:45.485 [http-apr-8080-exec-5] DEBUG c.j.f.c.s.storage.RedisBackedSessionMappingStorage - Attempting to remove Session=[8F24552DD446F669B7A522B1A8A0C86D]
2018-01-19 11:44:45.485 [http-apr-8080-exec-5] DEBUG c.j.f.c.s.storage.RedisBackedSessionMappingStorage - Found mapping for session.  Session Removed.
2018-01-19 11:44:45.486 [http-apr-8080-exec-5] DEBUG org.jasig.cas.client.session.SingleSignOutHandler - Invalidating session [8F24552DD446F669B7A522B1A8A0C86D] for token [ST-250-AouhaxqAjvmh5sfaP3Yz-8ec54e266608]

```

还有一种也是SLO时清理session的回调和上面的有什么区别呢？

上面的SLO是back channel logout方式，还有一种方式：front channel logout，后者是cas新版本提供的新方式，我这里没有使用，具体可以参考官方说明：[https://apereo.github.io/cas/5.0.x/installation/Logout-Single-Signout.html#turning-off-single-logout](https://apereo.github.io/cas/5.0.x/installation/Logout-Single-Signout.html#turning-off-single-logout)

开启trace日志查看回调是否发生错误来解决回调不生效问题

# Cookie问题

当使用单个域名时会出现Cookie清理问题从而导致SLO失效，因为CAS Server生成TGC时如果不设置cookie domain它会写在对接的service所在的域名下，最好的方式是让Cookie写在根域名的根Path（/）下，在CAS server端配置TGC的domain以及其他cookie参数，具体参考：

```
cas.tgc.path=/
cas.tgc.maxAge=-1
cas.tgc.domain=your.domain.com
#cas.tgc.signingKey=
cas.tgc.name=TGC
#cas.tgc.encryptionKey=
cas.tgc.secure=true
cas.tgc.httpOnly=true
cas.tgc.rememberMeMaxAge=1209600
cas.tgc.cipherEnabled=true
```

具体说明查看官方文档：[https://apereo.github.io/cas/5.0.x/installation/Configuration-Properties.html#ticket-granting-cookie](https://apereo.github.io/cas/5.0.x/installation/Configuration-Properties.html#ticket-granting-cookie)

## 举个例子理解一下

我有三个APP域名分别为：
```
https://account.domain.com
https://login.domain.com
https://app.domain.com
```

我生成的通配符证书域名为：`*.domain.com`

我三个APP在部署时jdk下放通配符域名证书

这样修改tgc配置为：

```
# cookie写的路径 / 为根域名下
cas.tgc.path=/
# cookie有效期，-1 为关闭浏览器自动清空
cas.tgc.maxAge=-1
# cookie写在那个域名下
cas.tgc.domain=domain.com
# cookie的名称
cas.tgc.name=TGC
# cookie开启器安全模式ssl
cas.tgc.secure=true
# cookie禁止js调用
cas.tgc.httpOnly=true
# 这两个采用默认配置即可
cas.tgc.rememberMeMaxAge=1209600
cas.tgc.cipherEnabled=true
```

# 用户数据源以及认证问题

CAS在这方面留了很多扩展的地方，而且很方便的配置就可以支持自定义

数据源支持的方式也有很多种（jdbc、mongodb、RestStorage、GIT、等）这里就不一一介绍了
认证方式支持的方式也很多种（Basic、OAuth2.0|1.0、Google Authenticator、LDAP、REST、OpenID、SPNEGO、等）这里就不一一介绍了

具体可以查看官方说明对应的配置：[https://apereo.github.io/cas/5.0.x/installation/Configuration-Properties.html](https://apereo.github.io/cas/5.0.x/installation/Configuration-Properties.html)

我使用的是jdbc方式

具体可以去github上查看cas-site源码：[cas-site](https://github.com/ningyu1/cas-site "项目地址") 

# CAS Server Ticket持久化问题

Ticket持久化方式也有很多中（JPA、Couchbase、Hazelcast、Infinispan、InMemory、Ehcache、Ignite、Memcached），默认方式（inMemory基于内存的），下面我给出JAP方式的配置参数：

```
cas.ticket.registry.jpa.jpaLockingTimeout=3600
cas.ticket.registry.jpa.healthQuery=SELECT 1
cas.ticket.registry.jpa.isolateInternalQueries=false
cas.ticket.registry.jpa.url=jdbc:mysql://127.0.0.1:3306/cas?useUnicode=true&characterEncoding=UTF-8&noAccessToProcedureBodies=true
cas.ticket.registry.jpa.failFast=true
cas.ticket.registry.jpa.dialect=org.hibernate.dialect.MySQL5Dialect
cas.ticket.registry.jpa.leakThreshold=10
cas.ticket.registry.jpa.jpaLockingTgtEnabled=false
cas.ticket.registry.jpa.batchSize=1
#cas.ticket.registry.jpa.defaultCatalog=
cas.ticket.registry.jpa.defaultSchema=cas
cas.ticket.registry.jpa.user=root
cas.ticket.registry.jpa.ddlAuto=validate
cas.ticket.registry.jpa.password=root@123456
cas.ticket.registry.jpa.autocommit=true
cas.ticket.registry.jpa.driverClass=com.mysql.jdbc.Driver
cas.ticket.registry.jpa.idleTimeout=5000

# 下面的参数根据实际情况选择使用
# 连接池
# cas.ticket.registry.jpa.pool.suspension=false
# cas.ticket.registry.jpa.pool.minSize=6
# cas.ticket.registry.jpa.pool.maxSize=18
# cas.ticket.registry.jpa.pool.maxWait=2000
# 签名与数据加解密密钥和算法
# cas.ticket.registry.jpa.crypto.signing.key=
# cas.ticket.registry.jpa.crypto.signing.keySize=512
# cas.ticket.registry.jpa.crypto.encryption.key=
# cas.ticket.registry.jpa.crypto.encryption.keySize=16
# cas.ticket.registry.jpa.crypto.alg=AES
```

这里需要注意的是，以上给出的配置参数是建议值，ddlauto默认值是create-drop，可选值有（create、create-drop、validate、update），具体含义可以查看官方文档：[https://apereo.github.io/cas/5.0.x/installation/JPA-Ticket-Registry.html](https://apereo.github.io/cas/5.0.x/installation/JPA-Ticket-Registry.html)，建议使用validate的方式，使用validate需要自己创建表，一共四张表下面贴出建表语句：

```
CREATE TABLE `locks` (
`application_id` varchar(255) NOT NULL,
`expiration_date` datetime DEFAULT NULL,
`unique_id` varchar(255) DEFAULT NULL,
`lockVer` int(11) NOT NULL DEFAULT '0',
PRIMARY KEY (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8


CREATE TABLE `oauth_tokens` (
`TYPE` varchar(31) NOT NULL,
`ID` varchar(255) NOT NULL,
`NUMBER_OF_TIMES_USED` int(11) DEFAULT NULL,
`CREATION_TIME` datetime DEFAULT NULL,
`EXPIRATION_POLICY` longblob NOT NULL,
`LAST_TIME_USED` datetime DEFAULT NULL,
`PREVIOUS_LAST_TIME_USED` datetime DEFAULT NULL,
`AUTHENTICATION` longblob NOT NULL,
`SERVICE` longblob NOT NULL,
PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

CREATE TABLE `serviceticket` (
`TYPE` varchar(31) NOT NULL,
`ID` varchar(255) NOT NULL,
`NUMBER_OF_TIMES_USED` int(11) DEFAULT NULL,
`CREATION_TIME` datetime DEFAULT NULL,
`EXPIRATION_POLICY` longblob NOT NULL,
`LAST_TIME_USED` datetime DEFAULT NULL,
`PREVIOUS_LAST_TIME_USED` datetime DEFAULT NULL,
`FROM_NEW_LOGIN` bit(1) NOT NULL,
`TICKET_ALREADY_GRANTED` bit(1) NOT NULL,
`SERVICE` longblob NOT NULL,
`ticketGrantingTicket_ID` varchar(255) DEFAULT NULL,
PRIMARY KEY (`ID`),
KEY `FK60oigifivx01ts3n8vboyqs38` (`ticketGrantingTicket_ID`),
CONSTRAINT `FK60oigifivx01ts3n8vboyqs38` FOREIGN KEY (`ticketGrantingTicket_ID`) REFERENCES `ticketgrantingticket` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

CREATE TABLE `ticketgrantingticket` (
`TYPE` varchar(31) NOT NULL,
`ID` varchar(255) NOT NULL,
`NUMBER_OF_TIMES_USED` int(11) DEFAULT NULL,
`CREATION_TIME` datetime DEFAULT NULL,
`EXPIRATION_POLICY` longblob NOT NULL,
`LAST_TIME_USED` datetime DEFAULT NULL,
`PREVIOUS_LAST_TIME_USED` datetime DEFAULT NULL,
`AUTHENTICATION` longblob NOT NULL,
`EXPIRED` bit(1) NOT NULL,
`PROXIED_BY` longblob,
`SERVICES_GRANTED_ACCESS_TO` longblob NOT NULL,
`ticketGrantingTicket_ID` varchar(255) DEFAULT NULL,
PRIMARY KEY (`ID`),
KEY `FKiqyu3qw2fxf5qaqin02mox8r4` (`ticketGrantingTicket_ID`),
CONSTRAINT `FKiqyu3qw2fxf5qaqin02mox8r4` FOREIGN KEY (`ticketGrantingTicket_ID`) REFERENCES `ticketgrantingticket` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
```

其他参数含义可以查看官方配置说明：[https://apereo.github.io/cas/5.0.x/installation/JPA-Ticket-Registry.html](https://apereo.github.io/cas/5.0.x/installation/JPA-Ticket-Registry.html)

# Client Server集群模式下session问题

当我们CAS Server准备好后，就要处理Client接入的问题，如果我们的Client服务是单机模式那没有任何问题，一旦放到集群环境下就会发生如下有意思的事情。

我前面说了CAS在授权回调时会做几件事，第一TG保存到Cookie，第二个保存ticketid对应的session关系以及session对象。

那么如果我们的Client服务是集群的会发生什么？

举个例子：

我的APP服务部署了2台服务（S1、S2）采用loadbalance映射一个域名出去访问，当CAS授权回调时被loadbalance路由到S1上，SingleSignOutFilter以及SingleSignOutHandler进行了TGC和SessionMappingStorage，默认的持久化方式是hash的方式，也就是说本地map方式，这样在下次访问到APP时被loadbalance路由到S2上就会发生什么有意思的事情呢？我相信做过分布式服务的应该都能猜出来什么问题。

APP：我没找到cas认证信息，跳转到cas login页面

CAS：我找到了你APP已经做过认证了，跳转到APP并且给你上次认证的ticlet

APP：我真没找到你的认证信息，跳转到cas login页面

CAS：你真的已经做过认证了，跳转到APP并且给你上次认证的ticlet

这样就会发生无线跳转死循环问题。

那如何解决上面的问题呢？

在分布式的环境下几乎服务都是集群的，甚至有很多公司会做异地多活等等。那么在集群环境下如何解决cas授权持久化的问题呢？很简单重新实现一个cas-client的SessionMappingStorage，这里可以使用很多方式，比如说：放到db、nosql的存储上（mongodb、redis）、memcache、分布式文件存储都可以。

我这里采用的是redis，而且我们dev和qa环境采用单机模式，stage和prod环境使用集群模式，因此我还做了集群和本地都兼容的方式，话不多说直接贴出实现代码

```
import java.util.HashMap;
import java.util.Map;
import javax.servlet.http.HttpSession;
import org.jasig.cas.client.session.SessionMappingStorage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import xxxxxxxx.framework.redis.client.IRedisClient;

public class RedisBackedSessionMappingStorage implements SessionMappingStorage {
    
    private final Logger logger = LoggerFactory.getLogger(getClass());
    
    /**
     * Maps the ID from the CAS server to the Session.
     */
    private final Map<String, HttpSession> MANAGED_SESSIONS = new HashMap<String, HttpSession>();

    /**
     * Maps the Session ID to the key from the CAS Server.
     */
    private final Map<String, String> ID_TO_SESSION_KEY_MAPPING = new HashMap<String, String>();
    
    private final static String NAME_SPACE = "CAS";
    
    private IRedisClient redisClient;
    
    /**
     * 在dev和qa环境使用单机模式：hash
     * 在stage和prod环境使用集群模式：redis
     */
    private String storageMode = "hash";

    /**
     * 获取 redisClient
     * @return the redisClient
     */
    public IRedisClient getRedisClient() {
        return redisClient;
    }

    /**
     * 设置 redisClient
     * @param redisClient the redisClient to set
     */
    public void setRedisClient(IRedisClient redisClient) {
        this.redisClient = redisClient;
    }

    /**
     * 获取 storageMode
     * @return the storageMode
     */
    public String getStorageMode() {
        return storageMode;
    }

    /**
     * 设置 storageMode
     * @param storageMode the storageMode to set
     */
    public void setStorageMode(String storageMode) {
        this.storageMode = storageMode;
    }

    @Override
    public HttpSession removeSessionByMappingId(String mappingId) {
        HttpSession session = null;
        if (storageMode.equals("hash")) {
            session = MANAGED_SESSIONS.get(mappingId);
        } else {
            session = redisClient.get(mappingId, NAME_SPACE, HttpSession.class, null);
        }

        if (session != null) {
            removeBySessionById(session.getId());
        }

        return session;
    }

    @Override
    public void removeBySessionById(String sessionId) {
        logger.debug("Attempting to remove Session=[{}]", sessionId);
        String key = null;
        if (storageMode.equals("hash")) {
            key = ID_TO_SESSION_KEY_MAPPING.get(sessionId);
        } else {
            key = redisClient.get(sessionId, NAME_SPACE, null);
        }

        if (logger.isDebugEnabled()) {
            if (key != null) {
                logger.debug("Found mapping for session.  Session Removed.");
            } else {
                logger.debug("No mapping for session found.  Ignoring.");
            }
        }
        
        if (storageMode.equals("hash")) {
            MANAGED_SESSIONS.remove(key);
            ID_TO_SESSION_KEY_MAPPING.remove(sessionId);
        } else {
            redisClient.del(key, NAME_SPACE);
            redisClient.del(sessionId, NAME_SPACE);
        }
    }

    @Override
    public void addSessionById(String mappingId, HttpSession session) {
        if (storageMode.equals("hash")) {
            ID_TO_SESSION_KEY_MAPPING.put(session.getId(), mappingId);
            MANAGED_SESSIONS.put(mappingId, session);
        } else {
            redisClient.set(session.getId(), NAME_SPACE, mappingId, -1);
            redisClient.set(mappingId, NAME_SPACE, session, -1);
        }

    }

}
```

这里使用的redis-client是我自己封装，使用文档在：[《RedisClient使用说明》](https://ningyu1.github.io/site/post/22-redis-client/)，支持redis集群模式：[《RedisClient升级支持Sentinel使用说明》](https://ningyu1.github.io/site/post/28-redis-client-sentinel/)，代码已经放到了github上：

项目地址：[redis-client](https://github.com/ningyu1/redis-client)

<a href="https://github.com/ningyu1/redis-client/releases"><img src="https://img.shields.io/github/release/ningyu1/redis-client.svg?style=social&amp;label=Release"></a>&nbsp;<a href="https://github.com/ningyu1/redis-client/stargazers"><img src="https://img.shields.io/github/stars/ningyu1/redis-client.svg?style=social&amp;label=Star"></a>&nbsp;<a href="https://github.com/ningyu1/redis-client/fork"><img src="https://img.shields.io/github/forks/ningyu1/redis-client.svg?style=social&amp;label=Fork"></a>&nbsp;<a href="https://github.com/ningyu1/redis-client/watchers"><img src="https://img.shields.io/github/watchers/ningyu1/redis-client.svg?style=social&amp;label=Watch"></a> <a href="http://www.gnu.org/licenses/gpl-3.0.html"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg"></a>


把上面的`RedisBackedSessionMappingStorage`类注入到`org.jasig.cas.client.session.SingleSignOutFilter`中即可

```
    <bean id="singleLogoutFilter" class="org.jasig.cas.client.session.SingleSignOutFilter">
    	<property name="sessionMappingStorage" ref="redisBackedSessionMappingStorage"></property>
    </bean>
    <bean id="redisBackedSessionMappingStorage" class="xxxxxxx.cas.session.storage.RedisBackedSessionMappingStorage">
    	<property name="redisClient" ref="redisClient"></property>
    	<property name="storageMode" value="${cas.session.storage.mode}"></property>
    </bean>
```

<span style='color:red'>**ps.参数cas.session.storage.mode，值：hash（本地map）、redis（集中存储）**</span>

## WEB服务端session集中存储处理

WEB服务端session集中存储处理方案也有很多种，使用tomcat可以使用TomcatRedisSessionManager来解决session集中存储问题，github地址：[https://github.com/ran-jit/tomcat-cluster-redis-session-manager](https://github.com/ran-jit/tomcat-cluster-redis-session-manager)

如果要自己实现也很简单，我这里大致说一下思路，需要包装一个可序列话的session，说白了就是包装一下session实现序列化接口：`java.io.Serializable`接口生成一个version id，包装一个获取器，在生成session的时候序列化写入集中存储返回id，在用的使用通过id获取，id可以使用jsessionid或者自己生成一个uuid都行。这个id可以放入浏览器cookie，也可以放入url每次带入,在登录成功后将session序列化存储到redis或其他cache、nosql、db等，在登出时清空即可，就看自己喜好来实现了。


到这里基本上对cas的使用经验就总结完了，我相信大家在使用cas时都会遇到上面的问题，希望这篇总结可以帮助到需要的人，感谢看到最后。

最后我的愿望是：世界和平，快乐编程每一天，keep real