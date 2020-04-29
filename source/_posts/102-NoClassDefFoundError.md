---
toc : true
title : "Trouble Shooting —— 莫名其妙的java.lang.NoClassDefFoundError: org.springframework.beans.FatalBeanException异常"
description : "Trouble Shooting —— 莫名其妙的java.lang.NoClassDefFoundError: org.springframework.beans.FatalBeanException异常"
tags : [
	"mybatis"
]
date : "2018-09-29 15:30:00"
categories : [
    "mybatis",
	"trouble shooting"
]
menu : "main"
---

* [问题描述](#desc)
* [问题分析](#analyze)
	* [尝试一](#retry1)
	* [尝试二](#retry2)
	* [尝试三](#retry3)
	* [尝试四](#retry4)
* [解决方法](#solution)

# <span id = "desc">问题描述</span>

最近运维在部署应用的时候偶尔会碰到下面的异常：

```
Exception in thread "main" java.lang.NoClassDefFoundError: org.springframework.beans.FatalBeanException
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:547)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:475)
    at org.springframework.beans.factory.support.AbstractBeanFactory$1.getObject(AbstractBeanFactory.java:304)
    at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:228)
    at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:300)
    at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:195)
    at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:700)
    at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:760)
    at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:482)
    at org.springframework.context.support.ClassPathXmlApplicationContext.<init>(ClassPathXmlApplicationContext.java:139)
    at org.springframework.context.support.ClassPathXmlApplicationContext.<init>(ClassPathXmlApplicationContext.java:93)
    at com.alibaba.dubbo.container.spring.SpringContainer.start(SpringContainer.java:50)
    at com.alibaba.dubbo.container.Main.main(Main.java:80)
```

这个异常看上去是`org.springframework.beans.FatalBeanException`在运行时找不到class，但是调试起来很懵逼。

# <span id = "analyze">问题分析</span>

## <span id = "retry1">尝试一</span>

怀疑这个类`org.springframework.beans.FatalBeanException`在`classloader`的时候无法找到。

这个类`org.springframework.beans.FatalBeanException`在`spring-beans`包下，查看打包的`lib`下存在`spring-beans`包，查看运行`jar`中的`META-INF`下的`MANIFEST.MF`文件中也有`lib/spring-beans-4.0.0.RELEASE.jar`

因此排除了这个怀疑。

ps.这里要区分一下`NoClassDefFoundError`和`ClassNotFoundException`异常看这篇[文章](https://blog.csdn.net/muskter/article/details/72236192)

## <span id = "retry2">尝试二</span>

这个类在`spring-beans`包中，那是不是这个jar包损坏无法读取？

查看了`jar`包信息以及打开与解压也排除了jar包损坏的可能性。

## <span id = "retry3">尝试三</span>

修改`log`级别改为`debug`看会不会有更多的日志输出。

通过日志级别的调整为`debug`后，除了都了一些`debug`的常规日志以外，错误相关的日志还是跟上面的输出一样，因此也是无济于事。

## <span id = "retry4">尝试四</span>

通过`arthas`观察`org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory`这个类的`doCreateBean`这个方法异常的输出。

```
arthas ${pid}
 
watch org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory doCreateBean "{params, throwExp}" -e -x 2
```

发现如下更多的日志：

```
ts=2018-09-25 18:06:37;result=@ArrayList[
    @Object[][
        @String[xxxMapper],
        @RootBeanDefinition[Root bean: class [org.mybatis.spring.mapper.MapperFa
ctoryBean]; scope=singleton; abstract=false; lazyInit=false; autowireMode=2; dep
endencyCheck=0; autowireCandidate=true; primary=false; factoryBeanName=null; fac
toryMethodName=null; initMethodName=null; destroyMethodName=null; defined in URL
 [jar:file:/E:/user/desktop/ningyu/Desktop/xxx-main-1.0.0-SNAPSHOT-201809251509/
lib/xxx-service-JD-1.0.0-SNAPSHOT.jar!/com/xxx/xxx/order/mapper/xxxMapper.class]],
        null,
    ],
    java.lang.NoClassDefFoundError: org.springframework.beans.FatalBeanException
        at org.springframework.beans.factory.support.AbstractAutowireCapableBean
Factory.doCreateBean(AbstractAutowireCapableBeanFactory.java:547)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBean
Factory.createBean(AbstractAutowireCapableBeanFactory.java:475)
        at org.springframework.beans.factory.support.AbstractBeanFactory$1.getOb
ject(AbstractBeanFactory.java:304)
        at org.springframework.beans.factory.support.DefaultSingletonBeanRegistr
y.getSingleton(DefaultSingletonBeanRegistry.java:228)
        at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBe
an(AbstractBeanFactory.java:300)
        at org.springframework.beans.factory.support.AbstractBeanFactory.getType
ForFactoryBean(AbstractBeanFactory.java:1420)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBean
Factory.getTypeForFactoryBean(AbstractAutowireCapableBeanFactory.java:788)
        at org.springframework.beans.factory.support.AbstractBeanFactory.isTypeM
atch(AbstractBeanFactory.java:543)
        at org.springframework.beans.factory.support.DefaultListableBeanFactory.
doGetBeanNamesForType(DefaultListableBeanFactory.java:384)
        at org.springframework.beans.factory.support.DefaultListableBeanFactory.
getBeanNamesForType(DefaultListableBeanFactory.java:361)
        at org.springframework.beans.factory.BeanFactoryUtils.beanNamesForTypeIn
cludingAncestors(BeanFactoryUtils.java:187)
        at org.springframework.beans.factory.support.DefaultListableBeanFactory.
findAutowireCandidates(DefaultListableBeanFactory.java:999)
        at org.springframework.beans.factory.support.DefaultListableBeanFactory.
doResolveDependency(DefaultListableBeanFactory.java:957)
        at org.springframework.beans.factory.support.DefaultListableBeanFactory.
resolveDependency(DefaultListableBeanFactory.java:855)
        at org.springframework.beans.factory.annotation.AutowiredAnnotationBeanP
ostProcessor$AutowiredFieldElement.inject(AutowiredAnnotationBeanPostProcessor.j
ava:480)
        at org.springframework.beans.factory.annotation.InjectionMetadata.inject
(InjectionMetadata.java:87)
        at org.springframework.beans.factory.annotation.AutowiredAnnotationBeanP
ostProcessor.postProcessPropertyValues(AutowiredAnnotationBeanPostProcessor.java
:289)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBean
Factory.populateBean(AbstractAutowireCapableBeanFactory.java:1185)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBean
Factory.doCreateBean(AbstractAutowireCapableBeanFactory.java:537)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBean
Factory.createBean(AbstractAutowireCapableBeanFactory.java:475)
        at org.springframework.beans.factory.support.AbstractBeanFactory$1.getOb
ject(AbstractBeanFactory.java:304)
        at org.springframework.beans.factory.support.DefaultSingletonBeanRegistr
y.getSingleton(DefaultSingletonBeanRegistry.java:228)
        at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBe
an(AbstractBeanFactory.java:300)
        at org.springframework.beans.factory.support.AbstractBeanFactory.getBean
(AbstractBeanFactory.java:195)
        at org.springframework.beans.factory.support.DefaultListableBeanFactory.
preInstantiateSingletons(DefaultListableBeanFactory.java:700)
        at org.springframework.context.support.AbstractApplicationContext.finish
BeanFactoryInitialization(AbstractApplicationContext.java:760)
        at org.springframework.context.support.AbstractApplicationContext.refres
h(AbstractApplicationContext.java:482)
        at org.springframework.context.support.ClassPathXmlApplicationContext.<i
nit>(ClassPathXmlApplicationContext.java:139)
        at org.springframework.context.support.ClassPathXmlApplicationContext.<i
nit>(ClassPathXmlApplicationContext.java:93)
        at com.alibaba.dubbo.container.spring.SpringContainer.start(SpringContai
ner.java:50)
        at com.alibaba.dubbo.container.Main.main(Main.java:80)
,
]
```

而且这个信息不停的打，并且看到的全是`xxxMapper`？

难道是`mybatis`的`mapper`代理类的创建出现了问题？

尝试本地通过代码的方式启动服务，没有任何问题。

又尝试本地通过打出的`zip`包，通过`java -jar`的方式启动，也没有任何问题。

 

这个时候就很头疼了，定位不到问题，而且问题不能重现。

 

网上能搜索到关于`mybatis`启动报`Stack overflow`的错误，难道我们这个问题跟他也有关系？于是尝试看一下`mybatis`的`mapper`代理自动创建的相关资料。

通过这篇[文章](https://blog.csdn.net/hongxingxiaonan/article/details/50354195)

当`MapperFactoryBean`实例生成之后，`Spring`给它注入`SqlSessionTemplate`。而注入`SqlSessionTemplate`的过程中会向容器获取所有的`Dao`，对于已经在容器中的`Dao`所对应的`bean`可以直接获取返回，若还没有创建`bean`，则`Spring`又会先创建这个`Dao`的`MapperFactoryBean`。创建`MapperFactoryBean`的时候会再次注入`SqlSessionTemplate`。就这样一直循环下去，直到所有的`Dao`都已经创建完毕，这个过程才算结束。

看来跟`mybatis`的关系应该很大，网上有有说`mybatis Mapper`有导致过`stack overflow`的错误，新想如果是`stack overflow`肯定应该是有明确的异常抛出，于是也是抱着尝试调整一下`jvm`的参数看看是否有惊喜。

```
-Xms1024m -Xmx1024m -XX:PermSize=256m -XX:MaxPermSize=256m -Xss256k
```

`stack overflow`应该调整`Xss`参数大小（`-Xss512k`）调整后重启，竟然成功了！竟然成功了！竟然成功了！

太不可思议了难道是`stack overflow`异常被吃掉了？而且`mapper`在创建的时候是递归，递归的层次越深越消耗stack大小，然后具体搜索mybatis导致`stack`异常的信息看到了这篇[文章](http://fantaxy025025.iteye.com/blog/2223217)，上面就是说`mybatis-spring`工具包有问题将异常吃掉了，具体`mybatis-spring`中的那段代码我还在定位，定位好了在更新文章

# <span id = "solution">解决方法</span>

调整xss参数，从xss256k调整为xss512k