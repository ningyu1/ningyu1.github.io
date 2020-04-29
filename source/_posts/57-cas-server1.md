---
toc : true
title : "CAS Server强制踢人功能实现方式"
description : "CAS Server强制踢人功能实现方式"
tags : [
	"CAS",
	"SLO",
	"Single Logout",
	"Ticket",
	"Ticket Registry",
	"Session Centralized Storage",
	"Cookie",
	"CAS Cluster",
	"CAS Server",
	"ForceLogout"
]
date : "2018-01-26 15:07:36"
categories : [
    "CAS"
]
menu : "main"
---

前面写过一篇关于CAS Server使用的经验总结，主要总结了CAS Server在使用的时候遇到的一些常见问题，比如说：证书、SLO、集群session处理、自定义用户认证、Ticket持久化等问题，传送门：[CAS使用经验总结，纯干货](https://ningyu1.github.io/site/post/54-cas-server/)，这次在基础上又增加了一个很常见很普通的问题，那就是踢人功能。

在管理系统这个领域里面踢人功能并不陌生，为了更好的管理用户串用账号，安全等方面考虑，接下来我们就细说一下CAS如何实现踢人的功能。

先说一下踢人功能的场景：

用户A在机器A上登录了APP1，用户A在机器B上登录APP1，在这种情况下后者登录需要踢掉前者的登录状态。

用户A在机器A上登录了APP1，用户B在机器B上登录了APP1，在这种情况下不存在踢人操作。

用户A在机器A上登录了APP1，用户A在机器B上登录了APP2，在这种情况下要分情况了，可以踢也可以不踢，这个就根据产品情况来选择，我们本次测试不能解决这个场景，如何解决我还在摸索中。

要做踢人功能之前先了解一下CAS的认证授权机制是如何完成的？

我这里直接引用官网的架构图：

![](/img/cas/1.png)

CAS Server与应用的Session交互图：

![](/img/cas/2.png)

其实CAS就是生成维护Ticket信息和应用session做绑定，当然它的Ticket实现还是比较复杂的，有树形关系以及和Service关联关系，从Ticket的源码能看的出来它有root的判断和Service的映射列表。

根据上面对CAS的理解，接下来我们说CAS怎么操作踢人功能？

# 踢人功能实现思路

在登录认证的时候记录一下，在下次登录获取到登录的人员列表，然后去匹配找出是否存在相同的用户，如果存在相同的用户，就注销掉这个用户的登录信息，这个是常规的思路和做法，但是在CAS里如何去找到切入点来进行判断操作呢？

我们在上一篇中提到了自定义认证逻辑，那么我们就可以继续在认证的这个切入点去进一步分析。

这里要先搞清楚一个概念：`Authentication`和`Authorization`这两者是不同的。

`Authentication`：字面意思认证，怎么理解这个认证呢？举个例子：我们每个人都有身份证，比如你去买火车票，买火车票需要出示身份证，那这个身份证就是证明你是你自己的凭证，那这个证明的过程就是认证。

`Authorization`：字面意思授权，怎么理解这个授权呢？举个例子：继续拿买火车票来说，你刚才出示了身份证证明了你自己，然后给了钱买了一张火车票，铁道部给了你一张票，这个票授权了你可以乘坐X车次X座位的权限其他车次你无权乘坐，那么这张票就是证明你确实买了X车次X座位的凭证，这就是授权。

换回系统的角度来说，认证就是验证用户名密码，授权就是验证你能不能操作某个功能的权限。

理解完认证和授权的区别，我们就开始从认证这块的切入点去看如何操作，CAS提供了这个类`TicketRegistry`它是管理所有`Ticket`的接口，通过调用`TicketRegistry.getTickets()`方法可以获取到所有认证用户的凭证。

```
/**
 * Retrieve all tickets from the registry.
 *
 * @return collection of tickets currently stored in the registry. Tickets
 * might or might not be valid i.e. expired.
 */
Collection<Ticket> getTickets();
```

那有了凭证信息就好更进一步操作。

CAS提供了`TicketGrantingTicket`，这个类是`Ticket`接口的一个实现类，可以通过`TicketGrantingTicket.getAuthentication().getPrincipal().getId()`来获取用户的身份。

```
/**
 * @return the unique id for the Principal
 */
String getId();
```

`getId()`返回的是登录的用户名，那拿到了用户名就要考虑如何注销的事情了。

刚才说到了它`TicketGrantingTicket`是`Ticket`接口的实现类，它的`t.markTicketExpired()`方法就是标记`Ticket`过期的动作。

```
/**
 * Mark a ticket as expired.
 */
void markTicketExpired();
```

光标记过期还不能完成注销操作，还需要通过`ticketRegistry.deleteTicket(t.getId())`来删除`Ticket`信息。

```
/**
 * Remove a specific ticket from the registry.
 * If ticket to delete is TGT then related service tickets are removed as well.
 *
 * @param ticketId The id of the ticket to delete.
 * @return the number of tickets deleted including children.
 */
int deleteTicket(String ticketId);
```

上面的分析过程看上去是可行的，那我们就来测试一下是否可以达到踢人功能的目的。

# 踢人功能实现过程

话不多说直接帖实现代码

```
/**
 * 登录成功，踢掉前一个相同登录的人
 * 
 * @param username
 */
public void forceLogout(final String username) {
	TicketRegistry ticketRegistry = (TicketRegistry) ApplicationContextProvider.getApplicationContext().getBean("ticketRegistry");
	final Collection<Ticket> ticketsInCache = ticketRegistry.getTickets();
	for (final Ticket ticket : ticketsInCache) {
		TicketGrantingTicket t = null;
		try {
			log.info("cast TicketGrantingTicketImpl");
			t = (TicketGrantingTicketImpl) ticket;
		} catch (Exception e) {
			log.error("cast TicketGrantingTicketImpl is error:", e);
			t = ((ServiceTicketImpl) ticket).getGrantingTicket();
		}
		if (t.getAuthentication().getPrincipal().getId().equals(username) && t.getId() != null) {
			/***
			 * 注销方法一 涉及到cookie的删除，但是无法获取response 该方法有待考究 未测试
			 */
			// centralAuthenticationService.destroyTicketGrantingTicket(t.getId());
			/***
			 * 注销方法二
			 */
			// t.expire();
			t.markTicketExpired();
			ticketRegistry.deleteTicket(t.getId());
		}
	}
}
```

上面的代码放到认证的切入点上调用，切入的位置如下：

1. 项目：`cas-site`
2. 类：`org.apereo.cas.adaptors.jdbc.QueryAndEncodeDatabaseAuthenticationHandler`
3. 方法：`authenticateUsernamePasswordInternal()`的`createHandlerResult()`之前调用。

代码如下：

```
@Override
protected HandlerResult authenticateUsernamePasswordInternal(final UsernamePasswordCredential transformedCredential)
        throws GeneralSecurityException, PreventedException {

    if (StringUtils.isBlank(this.sql) || StringUtils.isBlank(this.algorithmName) || getJdbcTemplate() == null) {
        throw new GeneralSecurityException("Authentication handler is not configured correctly");
    }

    final String username = transformedCredential.getUsername();
    try {
        // Get password and salt
        final Map<String, Object> rows = getJdbcTemplate().queryForMap(this.sql, username);
        final String encodedPassword = rows.get("password").toString();
        final String dbSalt = rows.get("salt").toString();
        SaltPasswordEncoder passwordEncoder = new SaltPasswordEncoder();
        passwordEncoder.setSalt(dbSalt);
        if (!passwordEncoder.matches(transformedCredential.getPassword(), encodedPassword)) {
            throw new FailedLoginException("Password does not match value on record.");
        }
		// 登录成功，踢掉前一个相同登录的人
        forceLogout(username);
        return createHandlerResult(transformedCredential, this.principalFactory.createPrincipal(username), null);

    } catch (final IncorrectResultSizeDataAccessException e) {
        if (e.getActualSize() == 0) {
            throw new AccountNotFoundException(username + " not found with SQL query");
        } else {
            throw new FailedLoginException("Multiple records found for " + username);
        }
    } catch (final DataAccessException e) {
        throw new PreventedException("SQL exception while executing query for " + username, e);
    }

}
```

cas-site项目我已经放入到了github，在这篇[《CAS使用经验总结，纯干货》](https://ningyu1.github.io/site/post/54-cas-server/)博文中可以找到。

万事俱备只欠东风了，接下来就是启动程序来验证它。

理想很美好，现实很骨感，出现了如下错误：

```
javax.persistence.TransactionRequiredException: No EntityManager with actual transaction available for current thread - cannot reliably process 'remove' call
	at org.springframework.orm.jpa.SharedEntityManagerCreator$SharedEntityManagerInvocationHandler.invoke(SharedEntityManagerCreator.java:282) ~[spring-orm-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at com.sun.proxy.$Proxy175.remove(Unknown Source) ~[?:?]
	at org.apereo.cas.ticket.registry.JpaTicketRegistry.removeTicket(JpaTicketRegistry.java:72) ~[cas-server-support-jpa-ticket-registry-5.0.4.jar:5.0.4]
	at org.apereo.cas.ticket.registry.JpaTicketRegistry.deleteTicketsFromResultList(JpaTicketRegistry.java:214) ~[cas-server-support-jpa-ticket-registry-5.0.4.jar:5.0.4]
	at org.apereo.cas.ticket.registry.JpaTicketRegistry.deleteTicketGrantingTickets(JpaTicketRegistry.java:244) ~[cas-server-support-jpa-ticket-registry-5.0.4.jar:5.0.4]
	at org.apereo.cas.ticket.registry.JpaTicketRegistry.deleteSingleTicket(JpaTicketRegistry.java:158) ~[cas-server-support-jpa-ticket-registry-5.0.4.jar:5.0.4]
	at org.apereo.cas.ticket.registry.AbstractTicketRegistry.deleteTicket(AbstractTicketRegistry.java:125) ~[cas-server-core-tickets-5.0.4.jar:5.0.4]
	at org.apereo.cas.ticket.registry.AbstractTicketRegistry$$FastClassBySpringCGLIB$$d3c67a11.invoke(<generated>) ~[cas-server-core-tickets-5.0.4.jar:5.0.4]
	at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204) ~[spring-core-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:651) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apereo.cas.ticket.registry.JpaTicketRegistry$$EnhancerBySpringCGLIB$$b6d104b8.deleteTicket(<generated>) ~[cas-server-support-jpa-ticket-registry-5.0.4.jar:5.0.4]
	at org.apereo.cas.ticket.registry.AbstractTicketRegistry$$FastClassBySpringCGLIB$$d3c67a11.invoke(<generated>) ~[cas-server-core-tickets-5.0.4.jar:5.0.4]
	at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204) ~[spring-core-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:651) ~[spring-aop-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at org.apereo.cas.ticket.registry.JpaTicketRegistry$$EnhancerBySpringCGLIB$$ef44b76a.deleteTicket(<generated>) ~[cas-server-support-jpa-ticket-registry-5.0.4.jar:5.0.4]
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[?:1.8.0_31]
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62) ~[?:1.8.0_31]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[?:1.8.0_31]
	at java.lang.reflect.Method.invoke(Method.java:483) ~[?:1.8.0_31]
```

**ps.异常堆栈很长我只截了一部分展示出来。**

这个错误是个什么鬼？从异常字面理解：在当前的线程中没有找到可用的事务，无法处理“删除”调用。

这个错误是`JPA`的错误，因为我的`Ticket Registry`配置的是`JPA`的方式，我猜测换成其他方式也会有类似的错误，我去掉`JPA`采用`InMemroy`的方式处理`Ticket Registry`，再次进行测试。

果然出现了类似的错误，如下：

```
javax.persistence.TransactionRequiredException: no transaction is in progress
	at org.hibernate.internal.SessionImpl.checkTransactionNeeded(SessionImpl.java:3428) ~[hibernate-core-5.2.2.Final.jar:5.2.2.Final]
	at org.hibernate.internal.SessionImpl.find(SessionImpl.java:3362) ~[hibernate-core-5.2.2.Final.jar:5.2.2.Final]
	at org.hibernate.internal.SessionImpl.find(SessionImpl.java:3342) ~[hibernate-core-5.2.2.Final.jar:5.2.2.Final]
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[?:1.8.0_31]
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62) ~[?:1.8.0_31]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[?:1.8.0_31]
	at java.lang.reflect.Method.invoke(Method.java:483) ~[?:1.8.0_31]
	at org.springframework.orm.jpa.ExtendedEntityManagerCreator$ExtendedEntityManagerInvocationHandler.invoke(ExtendedEntityManagerCreator.java:347) ~[spring-orm-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at com.sun.proxy.$Proxy175.find(Unknown Source) ~[?:?]
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[?:1.8.0_31]
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62) ~[?:1.8.0_31]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[?:1.8.0_31]
	at java.lang.reflect.Method.invoke(Method.java:483) ~[?:1.8.0_31]
	at org.springframework.orm.jpa.SharedEntityManagerCreator$SharedEntityManagerInvocationHandler.invoke(SharedEntityManagerCreator.java:298) ~[spring-orm-4.3.4.RELEASE.jar:4.3.4.RELEASE]
	at com.sun.proxy.$Proxy175.find(Unknown Source) ~[?:?]
```

说白了就是没有开启事务被禁止操作了。

这个怎么解决？cas-site采用的是`overlays`的方式构建，要看具体功能就要翻CAS的源码来看它是如何控制事务的。

于是去翻CAS的源码，翻源码也要讲究技巧的，要不然翻一天都翻不到关键点。

我们这里需要找如何开启事务的代码，还好CAS使用的是`Spring`来管理事务的，`Spring`的事务开启无非就这两种：一种是`AOP`方式，一种是手动方式。

那么`AOP`的方式可以使用注解（`Annotation`）也可以使用`XML`的配置去做。

CAS v5.0.4使用的`Spring Boot`的方式构建，说白了就是使用编程（`Java Config`）的方式替换`XML`的配置方式。而且我们使用的`Ticket Registry`是`JPA`，`JPA`的操作肯定要处理事务的，因此我们就锁定到注解（`Annotation`）的方式和`JPA`的实现上去找。

最终目标定位到了`cas-server-support-jpq-ticket-registry-5.0.4.jar`这个包上。

查看这个包的`org.apereo.cas.ticket.registry.JpaTicketRegistry`类代码

```
/**
 * JPA implementation of a CAS {@link TicketRegistry}. This implementation of
 * ticket registry is suitable for HA environments.
 *
 * @author Scott Battaglia
 * @author Marvin S. Addison
 * @since 3.2.1
 */
@EnableTransactionManagement(proxyTargetClass = true)
@Transactional(transactionManager = "ticketTransactionManager", readOnly = false)
public class JpaTicketRegistry extends AbstractTicketRegistry {
.....................其余的省略..............................
}
```

很明显就是我们说的注解（`Annotation`）的使用方式，我们再次修改代码。

## 踢人功能代码重构

`@EnableTransactionManagement(proxyTargetClass = true)`开启代理的方式，那我们就要抽一个接口和一个实现类来做，这里的具体原因就不多说了做多了都明白。

`@Transactional(transactionManager = "ticketTransactionManager", readOnly = false)`在实现类上直接使用这个注解方式。

直接贴重构后的代码：

新建接口`ForceLogoutManager`

```
public interface ForceLogoutManager {

	public void doLogout(final String username);
}
```

新建实现类`ForceLogoutManagerImpl`

```
import java.util.Collection;
import org.apereo.cas.ticket.ServiceTicketImpl;
import org.apereo.cas.ticket.Ticket;
import org.apereo.cas.ticket.TicketGrantingTicket;
import org.apereo.cas.ticket.TicketGrantingTicketImpl;
import org.apereo.cas.ticket.registry.TicketRegistry;
import org.apereo.cas.util.ApplicationContextProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.transaction.annotation.Transactional;

@EnableTransactionManagement(proxyTargetClass = true)
@Transactional(transactionManager = "ticketTransactionManager", readOnly = false)
@Component("forceLogoutManager")
public class ForceLogoutManagerImpl implements ForceLogoutManager {
	
	private final Logger log = LoggerFactory.getLogger(this.getClass());

	/**
	 * 登录成功，踢掉前一个相同登录的人
	 * 
	 * @param username
	 */
	public void doLogout(final String username) {
		TicketRegistry ticketRegistry = (TicketRegistry) ApplicationContextProvider.getApplicationContext()
				.getBean("ticketRegistry");
		final Collection<Ticket> ticketsInCache = ticketRegistry.getTickets();
		for (final Ticket ticket : ticketsInCache) {
			TicketGrantingTicket t = null;
			try {
				log.info("cast TicketGrantingTicketImpl");
				t = (TicketGrantingTicketImpl) ticket;
			} catch (Exception e) {
				log.error("cast TicketGrantingTicketImpl is error:", e);
				t = ((ServiceTicketImpl) ticket).getGrantingTicket();
			}
			if (t.getAuthentication().getPrincipal().getId().equals(username) && t.getId() != null) {
				/***
				 * 注销方法一 涉及到cookie的删除，但是无法获取response 该方法有待考究 未测试
				 */
				// centralAuthenticationService.destroyTicketGrantingTicket(t.getId());
				/***
				 * 注销方法二
				 */
				// t.expire();
				t.markTicketExpired();
				ticketRegistry.deleteTicket(t.getId());
			}
		}
	}
}
```

修改`org.apereo.cas.adaptors.jdbc.QueryAndEncodeDatabaseAuthenticationHandler`类`authenticateUsernamePasswordInternal`方法

```
public ForceLogoutManager getForceLogoutManager() {
	return (ForceLogoutManager) ApplicationContextProvider.getApplicationContext().getBean("forceLogoutManager");
}

@Override
protected HandlerResult authenticateUsernamePasswordInternal(final UsernamePasswordCredential transformedCredential)
        throws GeneralSecurityException, PreventedException {

    if (StringUtils.isBlank(this.sql) || StringUtils.isBlank(this.algorithmName) || getJdbcTemplate() == null) {
        throw new GeneralSecurityException("Authentication handler is not configured correctly");
    }

    final String username = transformedCredential.getUsername();
    try {
        // Get password and salt
        final Map<String, Object> rows = getJdbcTemplate().queryForMap(this.sql, username);
        final String encodedPassword = rows.get("password").toString();
        final String dbSalt = rows.get("salt").toString();
        SaltPasswordEncoder passwordEncoder = new SaltPasswordEncoder();
        passwordEncoder.setSalt(dbSalt);
        if (!passwordEncoder.matches(transformedCredential.getPassword(), encodedPassword)) {
            throw new FailedLoginException("Password does not match value on record.");
        }
		// 登录成功，踢掉前一个相同登录的人
        getForceLogoutManager().doLogout(username);
        return createHandlerResult(transformedCredential, this.principalFactory.createPrincipal(username), null);

    } catch (final IncorrectResultSizeDataAccessException e) {
        if (e.getActualSize() == 0) {
            throw new AccountNotFoundException(username + " not found with SQL query");
        } else {
            throw new FailedLoginException("Multiple records found for " + username);
        }
    } catch (final DataAccessException e) {
        throw new PreventedException("SQL exception while executing query for " + username, e);
    }

}
```

再次启动测试。

很顺利调用没有任何问题，到这里基于CAS v5.0.4的踢人功能的处理过程就整理完毕了。

最后还有一句话，我的愿望是：世界和平，快乐编程每一天，keep real！

