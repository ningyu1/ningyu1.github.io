---
toc : true
title : "Trouble Shooting —— CAS Server集群环境下TGC验证问题"
description : "Trouble Shooting —— CAS Server集群环境下TGC验证问题"
tags : [
	"CAS",
	"trouble shooting",
	"iphash",
	"TomcatRedisSessionManager",
	"Invalid cookie. Required remote address does not match ip"
]
date : "2019-10-15 14:05:53"
categories : [
    "CAS"
]
menu : "main"
---









之前写了一篇cas server故障排查的文章[《Trouble Shooting —— CAS Server集群环境下TGC验证问题排查，需要开启会话保持》](<https://ningyu1.github.io/blog/20180316/70-cas-server-pit.html>) ，之前这张文章写的是开启会话保持来解决这个故障，但是这个方式没有充分的发挥cas server集群的功能，因此这次讲一下另外一种解决方法，真正的解决cas server集群环境下的问题



我们可以点击上面的文章链接进去回顾一下具体的问题。



# 问题分析

错误是出在cas ticket cookie在cas server服务端验证时出现了问题，这里解释一下这个问题现象。

当我们cas server部署两台服务时，前端采用nginx做负载均衡，当我们访问cas server的时候nginx会随机选择一个服务端返回给前端，因此在第一次登陆的时候是由serverA生成的ticket，ticket中包含了客户端ip，当下次访问时路由到serverB时ticket验证的时候获取的客户端ip不一致导致的问题。

重点是在类：`org.apereo.cas.web.support.DefaultCasCookieValueManager`.`obtainCookieValue`方法

这里以cas server5.0.4版本为例看一下源码：

```java
	public String obtainCookieValue(final Cookie cookie, final HttpServletRequest request) {
        final String cookieValue = this.cipherExecutor.decode(cookie.getValue());
        LOGGER.debug("Decoded cookie value is [{}]", cookieValue);
        if (StringUtils.isBlank(cookieValue)) {
            LOGGER.debug("Retrieved decoded cookie value is blank. Failed to decode cookie [{}]", cookie.getName());
            return null;
        }

        final String[] cookieParts = cookieValue.split(String.valueOf(COOKIE_FIELD_SEPARATOR));
        if (cookieParts.length != COOKIE_FIELDS_LENGTH) {
            throw new IllegalStateException("Invalid cookie. Required fields are missing");
        }
        final String value = cookieParts[0];
        final String remoteAddr = cookieParts[1];
        final String userAgent = cookieParts[2];

        if (StringUtils.isBlank(value) || StringUtils.isBlank(remoteAddr)
                || StringUtils.isBlank(userAgent)) {
            throw new IllegalStateException("Invalid cookie. Required fields are empty");
        }

        if (!remoteAddr.equals(request.getRemoteAddr())) {
            throw new IllegalStateException("Invalid cookie. Required remote address does not match "
                    + request.getRemoteAddr());
        }

        final String agent = WebUtils.getHttpServletRequestUserAgent(request);
        if (!userAgent.equals(agent)) {
            throw new IllegalStateException("Invalid cookie. Required user-agent does not match " + agent);
        }
        return value;
    }
```

我们可以看出在ticket解决之后进行验证时获取的客户端ip是从：`request.getRemoteAddr()`获取的，这种方式获取在4、7层负载均衡的时候是无法获取真实的客户端ip。



接下来我们再看一下生成ticket的规则代码：

```java
	public String buildCookieValue(final String givenCookieValue, final HttpServletRequest request) {
        final StringBuilder builder = new StringBuilder(givenCookieValue);

        final ClientInfo clientInfo = ClientInfoHolder.getClientInfo();
        builder.append(COOKIE_FIELD_SEPARATOR);
        builder.append(clientInfo.getClientIpAddress());
        
        final String userAgent = WebUtils.getHttpServletRequestUserAgent(request);
        if (StringUtils.isBlank(userAgent)) {
            throw new IllegalStateException("Request does not specify a user-agent");
        }
        builder.append(COOKIE_FIELD_SEPARATOR);
        builder.append(userAgent);

        final String res = builder.toString();
        LOGGER.debug("Encoding cookie value [{}]", res);
        return this.cipherExecutor.encode(res);
    }
```



ticket的生成是从`clientInfo.getClientIpAddress()`获取客户端ip



我们再看`org.apereo.inspektr.common.web.ClientInfo`

```java
public ClientInfo(final HttpServletRequest request,
                      final String alternateServerAddrHeaderName,
                      final String alternateLocalAddrHeaderName,
                      final boolean useServerHostAddress) {

        try {
            String serverIpAddress = request != null ? request.getLocalAddr() : null;
            String clientIpAddress = request != null ? request.getRemoteAddr() : null;

            if (request != null) {
                if (useServerHostAddress) {
                    serverIpAddress = Inet4Address.getLocalHost().getHostAddress();
                } else if (alternateServerAddrHeaderName != null && !alternateServerAddrHeaderName.isEmpty()) {
                    serverIpAddress = request.getHeader(alternateServerAddrHeaderName) != null
                            ? request.getHeader(alternateServerAddrHeaderName) : request.getLocalAddr();
                }

                if (alternateLocalAddrHeaderName != null && !alternateLocalAddrHeaderName.isEmpty()) {
                    clientIpAddress = request.getHeader(alternateLocalAddrHeaderName) != null ? request.getHeader
                            (alternateLocalAddrHeaderName) : request.getRemoteAddr();
                }
            }

            this.serverIpAddress = serverIpAddress == null ? "unknown" : serverIpAddress;
            this.clientIpAddress = clientIpAddress == null ? "unknown" : clientIpAddress;

        } catch (final Exception e) {
            throw new RuntimeException(e);
        }
    }
```

从中看出5.0.4版本支持了传入header的来自定义客户端ip获取

但是5.0.4依然有问题它没有改全，从上面的ticket生成逻辑(`org.apereo.cas.web.support.DefaultCasCookieValueManager`)中可以看出来，生成的时候是通过：`clientInfo.getClientIpAddress()`，但是验证的时候是通过：`request.getRemoteAddr()`获取验证的，所以只要加了4,7层负载的话就会存在这个问题。



以上就是整个问题的分析过程，接下来看我们怎么来解决这个问题。



# 解决方案

cas在tikcet生成与验证的时候都有配置项提供自定义。

只要我们关闭ticket加解密就可以规避这个问题，但是安全性上稍微低一些，如果不想关闭ticket加解密休需要修改配置和代码。

1. 如果开启cas.tgc.cipherEnabled=true

   1. 需要同时多台server配置相同的cas.tgc.signingKey、cas.tgc.encryptionKey保证cookie加解密秘钥相同

   2. 修改代码让验证cookie获取客户端ip保持一致，如果是cas server 5.0.4版本可以修改`org.apereo.cas.audit.spi.config.CasCoreAuditConfiguration`类中的`org.apereo.inspektr.common.web.ClientInfoThreadLocalFilter`增加初始化参数来自定义客户端ip获取headerName

   3. ```
      @Bean
                public FilterRegistrationBean casClientInfoLoggingFilter() {
                    final FilterRegistrationBean bean = new FilterRegistrationBean();
                    bean.setFilter(new ClientInfoThreadLocalFilter());
                    bean.setUrlPatterns(Collections.singleton("/*"));
                    bean.setName("CAS Client Info Logging Filter");
                    bean.addInitParameter(ClientInfoThreadLocalFilter.CONST_IP_ADDRESS_HEADER,"X-Forwarded-For");
                    return bean;
                }
      ```

   4. 修改`org.apereo.cas.web.support.DefaultCasCookieValueManager`.`obtainCookieValue`代码，保持生成tikcet和验证ticket时获取客户端ip都使用`clientInfo.getClientIpAddress()`

2. 关闭cas tgc的加解密：cas.tgc.cipherEnabled=false，牺牲安全性就可以规避这个问题



<span style="color:blue">*建议使用配置的方式来调整，这样可以充分的发挥集群的功能。*</span>



世界和平、Keep Real！