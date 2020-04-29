---
toc : true
title : "Jenkins、SVN、MAVEN打包时区问题解决方案"
description : "Jenkins、SVN、MAVEN打包时区问题解决方案"
tags : [
	"jenkins",
	"svn",
	"maven"
]
date : "2018-01-09 18:30:36"
categories : [
    "jenkins",
	"svn",
	"maven"
]
menu : "main"
---

# 目录

1. [Jenkins时区设置问题](#jenkins)
2. [SVN更新代码时区问题](#svn)
3. [MAVEN打包时区问题](#maven)

# <a name="jenkins">一、Jenkins时区设置问题</a>

```
docker@jenkins:~$ cat /etc/default/jenkins|grep 2048
JAVA_ARGS="-Xmx2048m -Xms2048m -XX:PermSize=512m -XX:MaxPermSize=512m  -Dorg.apache.commons.jelly.tags.fmt.timeZone=Asia/Shanghai  -Djava.awt.headless=true"  # Allow graphs etc. to work even when an X server is present

```

增加时区参数：`-Dorg.apache.commons.jelly.tags.fmt.timeZone=Asia/Shanghai`

修改启动后查看jenkins系统参数：

![](/img/jenkins-svn-maven-timezone/1.png)

# <a name="svn">二、SVN更新代码时区问题</a>

svn时区依赖jenkins的时区设置

没有修改时区之前：

![](/img/jenkins-svn-maven-timezone/2.png)

能看的出来revision时间是有问题的跟我们机器时间不一致少了8小时

修复这个问题有两个方法

* 可以通过设置svn路径后增加@HEAD忽略掉revision来修复这个问题，具体设置如下

![](/img/jenkins-svn-maven-timezone/3.png)

* 修改jenkins时区，参考第一个问题
	* jenkins时区设置完之后svn拉取代码会自动修改：revision，如图

![](/img/jenkins-svn-maven-timezone/4.png)

# <a name="maven">三、MAVEN打包时区问题</a>

我项目中使用的是maven自己的timestamp

```
<timestamp>${maven.build.timestamp}</timestamp>
```

它的问题是：时区是UTC而且无法修改，如果要使用GMT+8，就需要插件提供支持

使用maven utc的timestamp构建出来的包名如下：

![](/img/jenkins-svn-maven-timezone/5.png)

我使用插件：`build-helper-maven-plugin`

在`pom`中增加`plugin` `build-helper-maven-plugin`来覆盖`maven`的`timestamp`变量：

```
<build>
    <plugins>
        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>build-helper-maven-plugin</artifactId>
            <version>3.0.0</version>
            <executions>
                <execution>
                    <id>timestamp-property</id>
                    <goals>
                        <goal>timestamp-property</goal>
                    </goals>
                    <configuration>
                        <name>timestamp</name>
                        <pattern>yyyyMMddHHmm</pattern>
                        <timeZone>GMT+8</timeZone>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

然后打包测试：

![](/img/jenkins-svn-maven-timezone/6.png)

测试通过，plugin配置建议配置在parent pom中这样所有子集项目都可以继承





