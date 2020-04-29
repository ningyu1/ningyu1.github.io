---
toc : true
title : "数据源连接泄漏问题分析"
description : "数据源连接泄漏问题分析"
tags : [
    "abandon connection",
	"connection leak",
	"datasource"

]
date : "2017-10-26 13:29:36"
categories : [
    "trouble shooting"
]
menu : "main"
---

# 目录：
1. [问题现象](#trouble)
2. [问题分析](#troubleshooting)
3. [修改验证](#validation)
4. [解决方案](#solutions)
5. [总结](#summed)

## <a name="trouble">问题现象</a>

开启druid数据源的连接泄漏开关（removeAbandoned=true），设置强制回收非法连接的超时时间为120（removeAbandonedTimeout=120,2分钟，目的是调试方便，让非法连接快速close掉）。
启动程序，等待2分钟会有连接泄漏的异常爆出，具体日志如下：

```
2017-10-25 17:19:52.858 [qtp365976330-72] WARN  org.jasig.cas.client.session.SingleSignOutHandler - Front Channel single sign out redirects are disabled when the 'casServerUrlPrefix' value is not set.
2017-10-25 17:21:56.531 [Druid-ConnectionPool-Destroy-678372234] ERROR com.alibaba.druid.pool.DruidDataSource - abandon connection, open stackTrace
    at java.lang.Thread.getStackTrace(Thread.java:1588)
    at com.alibaba.druid.pool.DruidDataSource.getConnectionDirect(DruidDataSource.java:995)
    at com.alibaba.druid.filter.FilterChainImpl.dataSource_connect(FilterChainImpl.java:4544)
    at com.alibaba.druid.filter.FilterAdapter.dataSource_getConnection(FilterAdapter.java:2723)
    at com.alibaba.druid.filter.FilterChainImpl.dataSource_connect(FilterChainImpl.java:4540)
    at com.alibaba.druid.filter.stat.StatFilter.dataSource_getConnection(StatFilter.java:661)
    at com.alibaba.druid.filter.FilterChainImpl.dataSource_connect(FilterChainImpl.java:4540)
    at com.alibaba.druid.pool.DruidDataSource.getConnection(DruidDataSource.java:919)
    at com.alibaba.druid.pool.DruidDataSource.getConnection(DruidDataSource.java:911)
    at com.alibaba.druid.pool.DruidDataSource.getConnection(DruidDataSource.java:98)
    at com.github.pagehelper.PageHelper.initSqlUtil(PageHelper.java:165)
    at com.github.pagehelper.PageHelper.intercept(PageHelper.java:148)
    at org.apache.ibatis.plugin.Plugin.invoke(Plugin.java:60)
    at com.sun.proxy.$Proxy64.query(Unknown Source)
    at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:108)
    at org.apache.ibatis.session.defaults.DefaultSqlSession.selectList(DefaultSqlSession.java:102)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke(Method.java:606)
    at org.mybatis.spring.SqlSessionTemplate$SqlSessionInterceptor.invoke(SqlSessionTemplate.java:358)
    at com.sun.proxy.$Proxy57.selectList(Unknown Source)
    at org.mybatis.spring.SqlSessionTemplate.selectList(SqlSessionTemplate.java:198)
    at com.xx.xx.xx.mybatis.MyBatisDao.selectList(MyBatisDao.java:391)
    at com.xx.xx.xx.xx.xx.xx.XXDaoImpl.queryByDeliverCode(XXDaoImpl.java:158)
    at com.xx.xx.xx.xx.xx.xx.XXServiceImpl.queryByDeliverCode(XXServiceImpl.java:159)
    at com.xx.xx.xx.xx.xx.xx.XXServiceImpl$$FastClassByCGLIB$$41eff1cc.invoke(<generated>)
    at org.springframework.cglib.proxy.MethodProxy.invoke(MethodProxy.java:204)
    at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:642)
    at com.xx.xx.xx.xx.xx.xx.XXServiceImpl$$EnhancerByCGLIB$$708c18f3.queryByDeliverCode(<generated>)
    at com.xx.xx.xx.xx.xx.XXController.initId(XXController.java:168)
    at com.xx.xx.xx.xx.xx.XXController.afterPropertiesSet(XXController.java:2080)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.invokeInitMethods(AbstractAutowireCapableBeanFactory.java:1612)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.initializeBean(AbstractAutowireCapableBeanFactory.java:1549)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:539)
    at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:475)
    at org.springframework.beans.factory.support.AbstractBeanFactory$1.getObject(AbstractBeanFactory.java:304)
    at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:228)
    at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:300)
    at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:195)
    at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:700)
    at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:760)
    at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:482)
    at org.springframework.web.context.ContextLoader.configureAndRefreshWebApplicationContext(ContextLoader.java:381)
    at org.springframework.web.context.ContextLoader.initWebApplicationContext(ContextLoader.java:293)
    at org.springframework.web.context.ContextLoaderListener.contextInitialized(ContextLoaderListener.java:106)
    at com.bstek.dorado.web.servlet.SpringContextLoaderListener.contextInitialized(SpringContextLoaderListener.java:73)
    at org.eclipse.jetty.server.handler.ContextHandler.callContextInitialized(ContextHandler.java:782)
    at org.eclipse.jetty.servlet.ServletContextHandler.callContextInitialized(ServletContextHandler.java:424)
    at org.eclipse.jetty.server.handler.ContextHandler.startContext(ContextHandler.java:774)
    at org.eclipse.jetty.servlet.ServletContextHandler.startContext(ServletContextHandler.java:249)
    at org.eclipse.jetty.webapp.WebAppContext.startContext(WebAppContext.java:1242)
    at org.eclipse.jetty.server.handler.ContextHandler.doStart(ContextHandler.java:717)
    at org.eclipse.jetty.webapp.WebAppContext.doStart(WebAppContext.java:494)
    at org.eclipse.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:64)
    at org.eclipse.jetty.server.handler.HandlerWrapper.doStart(HandlerWrapper.java:95)
    at org.eclipse.jetty.server.Server.doStart(Server.java:282)
    at org.eclipse.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:64)
    at net.sourceforge.eclipsejetty.starter.embedded.JettyEmbeddedAdapter.start(JettyEmbeddedAdapter.java:67)
    at net.sourceforge.eclipsejetty.starter.common.AbstractJettyLauncherMain.launch(AbstractJettyLauncherMain.java:84)
    at net.sourceforge.eclipsejetty.starter.embedded.JettyEmbeddedLauncherMain.main(JettyEmbeddedLauncherMain.java:42)
```

## <a name="troubleshooting">问题分析</a>

断点调试com.alibaba.druid.pool.DruidDataSource与com.alibaba.druid.pool.DruidPooledConnection中的close方法均有调用，如果都有关闭的话那怎么还会有连接泄漏呢？肯定有地方不对劲，因此进一步查询，开启druid的管理页面查看连接数，如下

![1.png](/img/connection-leak/1.png)

逻辑连接打开次数132，逻辑连接关闭次数131，发现问题有一个连接是没有放回连接池的，当到2分钟报了连接泄漏异常后再刷新查看，如下：

![2.png](/img/connection-leak/2.png)

逻辑连接打开次数和关闭次数一致了。

于是从上面的错误日志跟踪代码，第一感觉就是自己的业务代码出现了问题，找到业务代码的地方

```
at com.xx.xx.xx.xx.xx.xx.XXDaoImpl.queryByDeliverCode(XXDaoImpl.java:158)
at com.xx.xx.xx.xx.xx.xx.XXServiceImpl.queryByDeliverCode(XXServiceImpl.java:159)
at com.xx.xx.xx.xx.xx.xx.XXServiceImpl$$FastClassByCGLIB$$41eff1cc.invoke(<generated>)
```

打开：XXServiceImpl.queryByDeliverCode代码第159行，代码如下：

```
@Override
public DeliverEntity queryByDeliverCode(String code) {
    return deliverDao.queryByDeliverCode(code);
}
```

代码非常简单调用dao的方法，代开dao的queryByDeliverCode方法，代码如下：

```
@Override
public DeliverEntity queryByDeliverCode(String deliverCode) {
    Map<String,Object> map=new HashMap<String,Object>();
    map.put("deliverCode", deliverCode);
    List<DeliverEntity> list = selectList("com.xx.xx.xx.xx.xx.XXMapper.queryByDeliverCode", map);
    return list.size() > 0 ? list.get(0) : null;
}
```

代码也非常简单调用的是基类：MybatisDao的selectList方法，代码如下：

```
public List<E> selectList(final String aStatement, final Map<String, Object> aCondition) {
    SqlSession session = getSqlSessionTemplate();
    return session.selectList(aStatement, aCondition);
}
```

就是调用sqlsession的selectList方法，这个没有问题，连接是可以正常回收的，如果不能回收那上面的数字不可能是只有1个连接泄漏，应该是逻辑打开的132个都没有关闭才对。因此排除了这个地方，那还有什么地方会有问题呢？
肯定是有地方getConnection之后没有close导致!
继续分析连接泄漏打出来的日志！日志中的代码逐个分析，最终找到PageHelper.initSqlUtil方法

```
at com.github.pagehelper.PageHelper.initSqlUtil(PageHelper.java:165)
at com.github.pagehelper.PageHelper.intercept(PageHelper.java:148)
```

打开PageHelper.initSqlUtil代码，如下：

```
public synchronized void initSqlUtil(Invocation invocation) {
       if (sqlUtil == null) {
            String url = null;
            try {
                MappedStatement ms = (MappedStatement) invocation.getArgs()[0];
                MetaObject msObject = SystemMetaObject.forObject(ms);
                DataSource dataSource = (DataSource) msObject.getValue("configuration.environment.dataSource");
                url = dataSource.getConnection().getMetaData().getURL();
            } catch (SQLException e) {
                throw new RuntimeException("分页插件初始化异常:" + e.getMessage());
            }
            if (url == null || url.length() == 0) {
                throw new RuntimeException("无法自动获取jdbcUrl，请在分页插件中配置dialect参数!");
            }
            String dialect = Dialect.fromJdbcUrl(url);
            if (dialect == null) {
                throw new RuntimeException("无法自动获取数据库类型，请通过dialect参数指定!");
            }
            sqlUtil = new SqlUtil(dialect);
            sqlUtil.setProperties(properties);
            properties = null;
            autoDialect = false;
       }
}
```

貌似问题找到了，第8行代码：dataSource.getConnection()，但是没有在finally中对connection进行回收，罪魁祸首竟然是PageHelper

```
public Object intercept(Invocation invocation) throws Throwable {
    if (autoDialect) {
        initSqlUtil(invocation);
    }
    return sqlUtil.processPage(invocation);
}
```

根据代码逻辑发现当autoDialect=true时会调用initSqlUtil(invocation);，因此核对了我们的配置mybatis-config.xml

```
<plugins>
        <!-- com.github.pagehelper为PageHelper类所在包名 -->
        <plugin interceptor="com.github.pagehelper.PageHelper">
<!--             <property name="dialect" value="mysql" /> -->
             
            <property name="autoDialect" value="true" />
             
            <!-- 该参数默认为false -->
            <!-- 设置为true时，会将RowBounds第一个参数offset当成pageNum页码使用 -->
            <!-- 和startPage中的pageNum效果一样 -->
            <property name="offsetAsPageNum" value="true" />
            <!-- 该参数默认为false -->
            <!-- 设置为true时，使用RowBounds分页会进行count查询 -->
            <property name="rowBoundsWithCount" value="true" />
            <!-- 设置为true时，如果pageSize=0或者RowBounds.limit = 0就会查询出全部的结果 -->
            <!-- （相当于没有执行分页查询，但是返回结果仍然是Page类型） -->
            <property name="pageSizeZero" value="true" />
            <!-- 3.3.0版本可用 - 分页参数合理化，默认false禁用 -->
            <!-- 启用合理化时，如果pageNum<1会查询第一页，如果pageNum>pages会查询最后一页 -->
            <!-- 禁用合理化时，如果pageNum<1或pageNum>pages会返回空数据 -->
            <property name="reasonable" value="false" />
            <!-- 3.5.0版本可用 - 为了支持startPage(Object params)方法 -->
            <!-- 增加了一个`params`参数来配置参数映射，用于从Map或ServletRequest中取值 -->
            <!-- 可以配置pageNum,pageSize,count,pageSizeZero,reasonable,不配置映射的用默认值 -->
            <!-- 不理解该含义的前提下，不要随便复制该配置 -->
            <property name="params" value="pageNum=start;pageSize=limit;" />
        </plugin>
    </plugins>
```

我们果然配置的是：autoDialect=true，PageHelper在没有设置数据库方言的时候，他会主动的获取jdbc url来判断时那种数据库，因此会发生有一个连接是泄漏的，那这个问题如何解决呢？
我们打开PageHelper.setProperties方法，如下：

```
public void setProperties(Properties p) {
    //MyBatis3.2.0版本校验
    try {
        Class.forName("org.apache.ibatis.scripting.xmltags.SqlNode");//SqlNode是3.2.0之后新增的类
    } catch (ClassNotFoundException e) {
        throw new RuntimeException("您使用的MyBatis版本太低，MyBatis分页插件PageHelper支持MyBatis3.2.0及以上版本!");
    }
    //数据库方言
    String dialect = p.getProperty("dialect");
    if (dialect == null || dialect.length() == 0) {
        autoDialect = true;
        this.properties = p;
    } else {
        autoDialect = false;
        sqlUtil = new SqlUtil(dialect);
        sqlUtil.setProperties(p);
    }
}
```

只要我们在plugin配置的时候设置具体的方言就可以避免这个问题：dialect=mysql，如果有明确的dialect设置，autoDialect就会等于false，因此在intercept方法中就不会走initSqlUtil(invocation);方法，这就间接的避免了PageHelper的这个bug。
但是如果我们的数据源有不同的dialect怎么办呢？有两个办法解决
1. 构造SessionFactory的时候加载不同的mybatis-config.xml配置，如果有两种数据库类型就写两个mybatis-config.xml分别配置不同的dialect
2. 查看PageHelper高版本是否修复了这个bug，升级PageHelper版本
3. 修改PageHelper源码，在dataSource.getConnection()之后增加close调用

**ps. 我们现在用的PageHelper版本-->4.0.0，根据官方的chang log可以看出4.X的版本修复了这个问题，可以升级到4.x的final released version --> 4.2.1解决这个问题，5.x版本变更比较大。**

## <a name="validation">修改验证</a>

修改mybatis-config.xml的plugin中PageHelper的dialect的配置

```
<plugin interceptor="com.github.pagehelper.PageHelper">
            <property name="dialect" value="mysql" />
<!--             <property name="autoDialect" value="true" /> -->
 
</plugin>
```

修改后启动程序，打开druid的管理页面和等待2分钟超时看是否还有泄漏的异常爆出，如下：

![3.png](/img/connection-leak/3.png)

超过2分钟并没有泄漏异常爆出

## <a name="solutions">解决方案</a>

升级pagehelper版本-->4.2.1,升级jsqlparser版本–>0.9.5,其余配置无需变更

<span style="color: rgb(255,0,0);">如果升级了4.2.1，如果出现SqlUtil.java(120)行报NullPointerException，具体异常如下：</span>

![4.png](/img/connection-leak/4.png)

<span style="color: rgb(255,0,0);">遇到上面问题，请修改pagehelper的配置参数，参数修改有两种方式，如下：</span>

1. <span style="color: rgb(255,0,0);">直接配置dialect=目标数据源类型</span><span style="color: rgb(255,204,0);">**（适合使用场景：项目中只有一个固定的数据库类型，例如：mysql，无需开启自动发现dialect）**</span>
2. <span style="color: rgb(255,0,0);">配置autoRuntimeDialect=true走自动获取，这个属性是替换老属性（autoDialect），老的属性为了向下兼容在并发获取dialect时会有bug存在。</span><span style="color: rgb(255,204,0);">**（适合使用场景：项目中有多个数据库类型，需要运行中自动发现时使用）**</span>

## <a name="summed">总结</a>

这个问题告诉我们使用第三方的组件的风险很大。

