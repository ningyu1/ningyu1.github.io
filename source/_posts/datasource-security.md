---
toc : true
title : "讲一讲数据安全，如何有效预防脱库"
description : "讲一讲数据安全，如何有效预防脱库"
tags : [
	"datasource",
	"security"
]
date : "2020-12-29 18:49:30"
categories : [
    "security"
]
menu : "main"
---


今天讲一讲数据的安全问题，我们本篇不从DBA、网络架构层面来讲述数据安全，这部分由很专业的架构和云上产品来解决，本篇重点从开发人员角度讲述如何避免数据安全的漏洞。

我相信大部分人都看到过这样的新闻，某某论坛泄漏了用户密码，某某物流公司泄漏了用户的手机号等等，我一直坚信大部分数据泄漏都是内部管理出现了问题，大部分都是内部团队有意或无意泄漏了数据，如果要从外界通过漏洞攻克不是没有可能但是成本是巨大的，所以人为的泄漏往往是需要更加关注的问题，那作为软件生产的主力军（程序员）如何来避免挖坑？那我们接下来就主要讲讲从开发角度如何避免数据泄漏的漏洞。

从网上找了一些 [数据安全治理](https://zhuanlan.zhihu.com/p/26707158) 的相关办法，有兴趣可以参考一下。

我们从程序员角度来讲讲如何有效的预防数据安全问题。

# 数据的访问控制

我们先来看看哪些是经常访问数据库的用户？

1. 软件程序（应用程序、数据库中间件）
2. 人员：运维、开发、产品、等

那接下来我们就来看看从这几点如何来控制数据库的访问。

## 软件程序层面

这里说的软件程序包含：应用程序、数据库中间件等，作为数据库的第一用户我们如何有效的规避数据安全的问题呢？

我们先来说说现在的软件开发用到的一些框架，无论是`java、go、python`或其他，已经有很多丰富的`orm`和`datasource`框架，我下面罗列一些`java`中常用`jdbc`连接池和`orm`框架以及数据库中间件

|名称|说明|是否有加解密策略|
|---|---|---|
|druid|阿里巴巴开源的数据库连接吃|有|
|dbcp|Apache的开源数据库连接池|无|
|c3p0|一个开源的JDBC连接池|无|
|atomikos|一款分布式事务框架|无|
|mybatis|一款开源orm框架|无|
|hibernate|一款开源orm框架|无|
|mycat|开源分布式数据库中间件|无|
|shardingsphere|Apache的开源分布式数据库中间件|有|
|cobar|阿里巴巴开源分片数据库和表的代理|有|

我相信很多程序的数据库连接与密码都是通过配置文件来保存的，假如应用服务器被黑客利用软件漏洞拿下，我相信通过部署的软件可以翻出数据库连接的配置，那么针对这一点我们如何有效的避免呢？

### 数据库连接密码加密

一般我们为了做数据库高可用都会给数据库集群中间做一层代理，通过域名的方式来暴漏连接，这样做的好处就是数据库`failover`的时候应用程序可以不需要重启，只用重新创建连接即可。因此这层代理可以有效的防止数据库真实部署的机器被暴漏出去，起到了一定的安全作用。

虽然连接层面有一层代理来杜绝真实服务器被暴漏，但是我们在通过`jdbc`连接的时候往往是有密码访问的，我相信很多数据库的密码是明文的存储在配置文件中，虽然现在流行用`configcenter`配置中心来统一管理配置文件，如果使用明文来保存密码始终是无法规避泄漏的风险的，因为应用程序始终要进行连接，在连接的时候要读取配置，不管配置是从云端同步下来还是从本地读取，只要是明文存储密码的就会存在安全问题。

其实大多的数据库连接池都有对数据库访问密码加解密的功能，因此我们可以通过把数据库访问的密码进行加密来解决安全问题。

下来我使用`druid`举个例子，具体的看看如何使用

可以查看`druid`官方 [示例](https://github.com/alibaba/druid/wiki/%E4%BD%BF%E7%94%A8ConfigFilter)

通过使用`ConfigFilter`为数据库密码提供加密功能

```xml
<bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource"
        destroy-method="close">
    .................
    <property name="filters" value="${filters}" /> 如果fitlers走的disconf配置，请看disconf中修改说明
    <property name="filters" value="stat,config" /> 如果没有fitlers配置增加配置
    filters配置以上两种2选一
     
    <property name="connectionProperties" value="config.decrypt=true;config.decrypt.key=${publickey}" />
    .................
</bean>
```

```properties
filters=stat
改为
filters=stat,config
 
jdbc.xxxx.password=123456
改为
jdbc.xxxx.password=加密后的值
 
增加
publickey=公钥
```

ps. 如果使用的是配置中心那么创建对应的配置项即可。

非对称秘钥对的生成方式有很多种，这里我给个[在线生成的链接](http://web.chacuo.net/netrsakeypair) 加密后的密文是一段比较长的字符，例如下面这段示例

```properties
jdbc.password=p9i+fChqlaYnfhI+NoJqmrGwTyWwlFZ1W7Vi7i2MGZ8agFkGxGr/kWU//yDvPyXZ6YwJwnMKQ4zXpTZnfxWaRjfqWIRG+JzxSdSYEMp/bRCiIvzF6y8FdVCqN/0m0eQeZFvMCdIf4wqhKF0QRCEOTysZ3oGg7t5o35CIMpV1A5Y=
```

其他的`jdbc`连接池也都有类似的功能，但是不排除有一些没有这个功能的怎么办？

那么就需要我们自己动手进行开发来增强这部分功能，首先我们需要了解数据库连接加解密的思路，只要有思路实现都是很简单的，其实数据库连接加解密思路很简单，在真正创建数据库连接的时候读取加密的密码进行解密后再进行数据库连接，那接下来我们给`dbcp`扩展这个功能。

```java
import java.sql.SQLFeatureNotSupportedException;
import java.util.Properties;
import java.util.logging.Logger;

import org.apache.commons.dbcp.BasicDataSource;
import org.slf4j.LoggerFactory;

public class SecurityBasicDataSource extends BasicDataSource {
	
	private final org.slf4j.Logger logger = LoggerFactory.getLogger(SecurityBasicDataSource.class);

	@Override
	public Logger getParentLogger() throws SQLFeatureNotSupportedException {
		throw new SQLFeatureNotSupportedException();
	}

	@Override
	public void setPassword(String password) {
		try {
            //这里可以从任意地方读取数据库配置
			Properties p = ConfigLoaderUtils.loadConfig("jdbc.properties");
			String publickey = p.getProperty("publickey");
            //ConfigTools是实现私钥、公钥对加解密实现
			password = ConfigTools.decrypt(publickey, password);
			super.setPassword(password);
		} catch(Exception e) {
			logger.error("解密password出错", e);
		}
	}

}
```

* 首先我们继承`dbcp`数据源`org.apache.commons.dbcp.BasicDataSource`
* 重写`setPassword`
* 设置密码的时候通过公钥和密文进行解密

这样我们就给`dbcp`扩展了数据库连接加解密的功能，是不是很简单。

到这里我们就对数据库连接密码加密的方法介绍完毕，这样做的好处有什么呢？假设当应用服务器被坏人俘虏后，他想通过应用的配置信息轻松的获取数据库访问密码是不太可能，采用 [公开密钥加密](https://zh.wikipedia.org/wiki/%E5%85%AC%E5%BC%80%E5%AF%86%E9%92%A5%E5%8A%A0%E5%AF%86) 安全性还是很高的，它是一种非对称加密算法想要了解更多的可以点开维基百科的连接查看。

### 敏感数据加解密

前面我们介绍完了数据库连接上的安全问题以及如何解决安全问题，接下来我们继续介绍一下数据库中存储的敏感数据应该如何处理。

我相信很多人都接触过导出生产数据需要经过 [数据脱敏](https://baike.baidu.com/item/%E6%95%B0%E6%8D%AE%E8%84%B1%E6%95%8F) ，需要经过数据脱敏的大多都是存储的明文数据，比如说用户的手机号、详细地址、银行卡号、信用卡验证码、用户密码、等。

如果我们将这些敏感数据在存储入库的时候进行加密，数据库中存储的是密文数据，这样及时被脱裤我相信也没有那么容易破解，有人可能说密码包里破解外界有 [彩虹表](https://zh.wikipedia.org/wiki/%E5%BD%A9%E8%99%B9%E8%A1%A8) ,彩虹表是一个用于加密散列函数逆运算的预先计算好的表，常用于破解加密过的密码散列，针对于用户详细地址、联系方式我相信彩虹表是无能为力的，如果使用暴力破解基本上时间成本也是难以想象的，可能需要xxxxxx亿年，哈哈哈。

我们对数据加解密使用对称加解密算法`AES`或`DES`，为什么不使用非对称的[公开密钥加密](https://zh.wikipedia.org/wiki/%E5%85%AC%E5%BC%80%E5%AF%86%E9%92%A5%E5%8A%A0%E5%AF%86) ？

虽然非对称加解密算法安全性高，但是非对称加解密算法加密后的值太长不利于存储，所以我们需要使用固定长度或者可控长度的加解密算法，刚好对称加解密算法符合要求，这里使用`DES`作为示例，当然可以替换成任意的加解密算法。

先说说数据落库时的加解密实现思路，假设我们需要存储用户详情，其中有姓名、电话、联系地址、银行卡号等信息，我们在持久化用户详情的时候对敏感字段进行加密计算出密文，再将密文存入数据库，当查询用户详情的时候，先从数据库查询出密文，通过对密文的解密和脱敏再返回给前台，这样我们就可以达到我们想要的效果，这里需要特殊说明一下，密文对模糊查询不是很友好，但是也可以实现模糊查询，具体的实现思路有很多种，这里我们就不多做介绍，感兴趣的话我后面可以单独出一篇支持模糊查询的加解密算法，回到主题我们就以这个案例作为示例进行实现。

首先我们需要对敏感字段进行打标记，`java`的`annotation`可以帮助我们实现打标

```java
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface Cipher {

}
```

我们可以给用户对象的敏感字段：手机号、银行卡、详细地址 上标注`@Cipher`注释，说明这几个字段我们在保存、修改的时候需要加密，在查询的时候需要解密。

下来我们就要找一个公共的地方来统一的进行加解密处理，作为一名合格的程序员需要想尽一切办法来偷懒，并不是在所有`CRUD`的地方进行加解密调用这样会很傻很天真，作为被广泛使用的`orm`框架之一的`mybatis`这里我使用它作为示例讲解实现思路。

`mybatis`提供拦截器机制，可以对执行的`CRUD`进行拦截处理操作，[pagehelper](https://github.com/pagehelper/Mybatis-PageHelper) 是一个分页的`mybatis`插件，就是利用拦截的机制来扩展分页功能。

我们刚才有说过我们需要对`insert`、`update`操作进行加密，对`select`操作进行解密，在`mybatis`的底层保存和修改都是`update`方法，查询都是`query`方法，刚好我们就对这两个方法进行拦截处理。

```java
import java.lang.reflect.Field;
import java.util.List;
import java.util.Properties;

import org.apache.commons.lang3.StringUtils;
import org.apache.ibatis.executor.Executor;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Plugin;
import org.apache.ibatis.plugin.Signature;
import org.apache.ibatis.session.ResultHandler;
import org.apache.ibatis.session.RowBounds;
import org.apache.ibatis.session.defaults.DefaultSqlSession.StrictMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Intercepts({
        @Signature(type = Executor.class, method = "update", args = { MappedStatement.class, Object.class }),
        @Signature(type = Executor.class, method = "query", args = { MappedStatement.class, Object.class,
                RowBounds.class, ResultHandler.class }) })
public class CipherHelper implements Interceptor {
    
    private final Logger logger = LoggerFactory.getLogger(CipherHelper.class);

    /**
     * 加密密钥</br> 为null，使用默认密钥进行加解密</br>
     */
    private String secureKey = null;
    /**
     * 是否允许宽容处理</br> 宽容处理的话，使用原值，反之throw {@link CipherException}</br>
     */
    private boolean lenient = false;

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        String methodName = invocation.getMethod().getName();
        if (methodName.equals("update") || methodName.equals("query")) {
             Object parameter = invocation.getArgs()[1];
            if (parameter instanceof List) {
                List<?> list = (List<?>) parameter;
                for (Object obj : list) {
                    encrypt(obj);
                }
            } else if(parameter instanceof StrictMap) {
                StrictMap<?> strictMap = (StrictMap<?>) parameter;
                if (strictMap.containsKey("list")) {
                    List<?> list = (List<?>) strictMap.get("list");
                    for (Object obj : list) {
                        encrypt(obj);
                    }
                } else if (strictMap.containsKey("array")) {
                    Object[] objects = (Object[]) strictMap.get("array");
                    for (Object obj : objects) {
                        encrypt(obj);
                    }
                }
            } else {
                encrypt(parameter);
            }
        }
        Object returnValue = invocation.proceed();
        if (methodName.equals("query")) {
            if (returnValue instanceof List) {
                List<?> list = (List<?>) returnValue;
                for (Object obj : list) {
                    decrypt(obj);
                }
            } else {
                decrypt(returnValue);
            }
        }
        return returnValue;
    }

    /**
     * 加密处理
     * 
     * @param parameter
     * @throws IllegalAccessException
     */
    private void encrypt(Object parameter) throws IllegalAccessException {
        if (parameter == null) return;
        Class<?> clazz = parameter.getClass();
        if (!clazz.getSimpleName().endsWith("Entity")) {
            return;
        }
        for (; clazz != Object.class; clazz = clazz.getSuperclass()) {
            Field[] fields = clazz.getDeclaredFields();
            for (int i = 0; i < fields.length; i++) {
                if (!fields[i].isAnnotationPresent(Cipher.class)) {
                    continue;
                }
                if (!fields[i].getType().equals(String.class)) {
                    logger.debug("加密字段只支持String类型,当前类型非String,跳过!");
                    continue;
                }
                fields[i].setAccessible(true);
                String v = (String) fields[i].get(parameter);
                if (StringUtils.isBlank(v)) {
                    logger.debug("加密字段值为null,跳过!");
                    continue;
                }
                try {
                    String crypt = DESTools.encrypt(secureKey, v);
                    fields[i].set(parameter, crypt);
                    logger.debug("加密处理字段,{}", fields[i].getName());
                } catch (Exception e) {
                    if (lenient) {
                        logger.warn("加密处理失败,宽容处理使用原值");
                    } else {
                        throw new CipherException("加密处理失败,不允许宽容处理["+v+"]", e);
                    }
                }
            }
        }
    }

    /**
     * 解密处理
     * 
     * @param obj
     * @throws IllegalAccessException
     * @throws Exception
     */
    private void decrypt(Object obj) throws IllegalAccessException, Exception {
        if (obj == null) return;
        Class<?> clazz = obj.getClass();
        if (!clazz.getSimpleName().endsWith("Entity")) {
            return;
        }
        for (; clazz != Object.class; clazz = clazz.getSuperclass()) {
            Field[] fields = clazz.getDeclaredFields();
            for (int i = 0; i < fields.length; i++) {
                if (!fields[i].isAnnotationPresent(Cipher.class)) {
                    continue;
                }
                if (!fields[i].getType().equals(String.class)) {
                    logger.debug("解密字段只支持String类型,当前类型非String,跳过!");
                    continue;
                }
                fields[i].setAccessible(true);
                String v = (String) fields[i].get(obj);
                if (StringUtils.isBlank(v)) {
                    logger.debug("解密字段值为null,跳过!");
                    continue;
                }
                try {
                    String crypt = DESTools.decrypt(secureKey, v);
                    fields[i].set(obj, crypt);
                    logger.info("解密处理字段,{}", fields[i].getName());
                } catch (Exception e) {
                    if (lenient) {
                        logger.warn("解密处理失败,宽容处理使用原值");
                    } else {
                        throw new CipherException("解密处理失败,不允许宽容处理["+v+"]", e);
                    }
                }
            }
        }

    }

    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }

    @Override
    public void setProperties(Properties properties) {
        if (properties != null && StringUtils.isNotBlank(properties.getProperty("secureKey"))) {
            this.secureKey = properties.getProperty("secureKey");
        }
        if (properties != null && StringUtils.isNoneBlank(properties.getProperty("lenient"))) {
            this.lenient = Boolean.parseBoolean(properties.getProperty("lenient"));
        }

    }

}
```

通过`mybatis`的插件扩展机制在执行过程进行拦截处理，`plugin`方法是插件的装载方法，`setProperties`方法设置关键属性，比如说密钥串。

`encrypt`加密方法，这里加密方法需要注意的是，`mybatis`参数支持[`Pojo`](https://baike.baidu.com/item/POJO) 和`Map`、`StrictMap`、`List`、`Array`，我们使用注解`@Cipher`是用在类上的所以只对`Pojo`生效，如果是`Map`它天生的`key，value`格式无法支持打标，我们这里对`Map`类型进行跳过不处理，如果非要处理`Map`也是有办法的，需要固定加解密的`key`值，对特定的`key`进行识别并加解密替换`value`，我们通过查找使用注解`@Cipher`的字段进行加密并且回填值。

`decrypt`解密方法，主要用在查询时的解密，这里需要注意的是查询有可能返回特定的`Pojo`也可能返回`List`，所以这里解密的时候需要根据类型来分别处理，如果是`List`需要进行很层次查找，如果是`Pojo`那就查找使用注解`@Cipher`的字段进行解密并且回填值。

`intercept`拦截方法，在`update`、`query`前后进行拦截处理，在这个方法里需要进行如下步骤：

* 识别当前执行的`method`是`update`还是`query`
    * 如果是`update`那就进行加密
    * 如果是`query`那就进行解密
* 识别参数类型是`List`、`StrictMap`、`Pojo`
    * 如果是`List`需要再深层次看一下`List`里是什么类型，这里建议使用递归方式
        * 如果`List`里是`Pojo`那就循环调用`encrypt`方法
        * 如果`List`里是`Map`跳过处理，或者使用上面我们说的识别某些固定`key`进行加密处理
    * 如果是`StrictMap`需要再深层次看一下`StrictMap`里是什么类型，这里建议使用递归方式
        * 如果`StrictMap`里是`list`那就循环调用`encrypt`方法
        * 如果`StrictMap`里是`array`那就循环调用`encrypt`方法
    * 如果是`Pojo`那就调用`encrypt`方法
* 执行sql处理获取返回值
* 获取返回值并且执行的方法是`query`时，进行解密处理
    * 识别返回的类型是`List`还是`Pojo`
        * 如果是`List`深层次查找内部类型，这里建议使用递归方式
            * 如果`List`里是`Pojo`那就循环调用`decrypt`方法
            * 如果`List`里是`Map`跳过处理，或者使用上面我们说的识别某些固定`key`进行解密处理
        * 如果是`Pojo`那就调用`decrypt`方法

到这里数据加解密的核心逻辑就介绍完了。

这里我们回顾一下，我们先是对数据库连接密码进行加解密，然后又对敏感数据落库和查询时进行加解密，第一步连接密码加密预防坏人即使攻击拿到了应用服务器的操作权限他也无法轻易的攻克我们的数据库访问密码，第二步敏感数据加解密预防坏人即使攻克了我们的数据库他也无法获取用户的隐私数据，这样就有效的保证了用户隐私数据的安全性。

到这里我们就对软件程序层面的数据安全防护手段介绍完毕，接下来我们再从人员访问控制方面来看有什么有效的手段。

## 人员层面

前面我们说了绝大多数的数据泄密都不是技术问题而是人员管理问题，我们要对人员进行有效的管理与控制。

### 开发或测试人员

这类人一般对数据是有`CRUD`的诉求，首先针对开发人员的控制有如下几个当面

* 开发人员只能连接测试环境数据库，不允许连接生产数据库，及时连接vpn也不行。
* 开发人员申请数据库需要走运维的工单流程，运维提供数据库连接密码时应直接提供密文，或者运维直接给配置到配置中心。
* 配置文件中禁止存储明文密码，配置中心的配置也一样，需要对jdbc等其他敏感密码进行脱敏处理。
* 生产服务器需要通过跳板机访问，禁止开发使用`root`直接操作，如果看应用日志可以走日志平台，实在没有日志平台可以给跳板机开通`app`用户只给查看固定目录日志的权限，如果要发布走`devops`平台，如果没有可以提供给运维进行发布。
* 查询生产数据走`dms`平台，对敏感信息进行脱敏或隐藏，对上线的sql和日常的查询日志做到`dms`可管控。
* 提交到开放环境时需要注意一下几点
    * 提交到开放的仓库（`github`、`gitlab`、`gitee`等）时需要对代码进行审核，避免有hardcode的敏感信息，这里敏感信息包含公司服务器密码、ip、端口、密钥等
    * 提交到开放的论坛（`csdn`、`oschina`、`知乎`、`公众号`、`社区分享`等）时需要对文章进行审核，避免有不允许公开的技术细节、或者敏感的信息。

### 运维或DBA人员

这类人一般权限都很高，出问题概率最高的人员，有很多删库跑路或误操作`rm -rf`的例子哈哈哈！所以这类人更要重点管控。

* 需要搭建和处理运维工单平台，用于开发提出的运维资源申请，尤其是数据库密码，直接提供加密后的密文和公钥。
* 需要搭建和处理数据库管理工具`dms`，用于开发日常生产数据查询和发版时`SQL`升级。
* 需要提供跳板机和给跳板机提供不同等级的用户，提供给特别需要的人访问生产环境机器。
* 需要提供`devops`平台或者自动化发版工具，避免手动操作失误带来问题，对开发提供升级发布的流水线。
* 对服务器密码需要进行加密存储，可以借助密码管理工具。
* 运维最好也不要使用`root`用户操作服务器，使用特定权限的用户操作。
* `dba`最好也不要使用`root`用户操作数据库，使用特定权限的用户操作。
* 制定责任人机制，对应的责任项必须到具体人，具体可以参考 [责任分配矩阵RAM](https://baike.baidu.com/item/%E8%B4%A3%E4%BB%BB%E5%88%86%E9%85%8D%E7%9F%A9%E9%98%B5) 。
* 关键重要的操作需要至少两个人在场，具体可以参考 [责任分配矩阵RAM](https://baike.baidu.com/item/%E8%B4%A3%E4%BB%BB%E5%88%86%E9%85%8D%E7%9F%A9%E9%98%B5) 。

### 产品或业务人员

这类人一般对数据有查询的诉求，而且查询大多是分析类软件，一般统一走公司`BI`工具，也有少部分有修改的诉求。

* 需要查询分析类数据，统一接入`BI`工具，并且`BI`工具需要有功能和数据权限，并对敏感数据导出应该控制，导出走审批或脱敏。
* 如果提交数据变更，统一接入`dms`平台。
* 产品处理的分析文件（word、excel、ppt）应该进行加密，这种一般依赖公司引入文档安全的解决方案，要花钱的，如果不想花钱那就没啥好办法。

# 总结

到这里整篇也就差不多都介绍完了，我们现在回顾一下，首先我们介绍了数据安全的问题，并且说明了安全问题一般发生在两个方面，一个是软件程序，一个是人员管理。

我们在软件程序方面介绍了两种预防数据安全的手段，一个是数据库连接密码加解密，一个是数据加解密，数据库连接加密可以有效预防服务器被攻击后通过翻找程序来进一步攻击数据库，数据加解密可以有效预防数据库被攻击或脱库后泄漏用户及公司隐私数据。

我们在人员方面对人员进行了分类，针对每一类人的诉求谈了管控的手段，说了这么多的控制手段，并不是说对员工不信任，我们这里说的控制并不等于限制，我们需要搭建一套有序的安全的管理机制，在安全的范围内给员工提供最大化的发挥空间，规避有心或无心的泄密。



















