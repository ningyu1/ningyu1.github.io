---
toc : true
title : "BTrace使用笔记"
description : "BTrace使用笔记"
tags : [
	"btrace"

]
date : "2017-11-15 11:00:36"
categories : [
    "trace",
	"java"
]
menu : "main"
---

## BTrace是什么？

Btrace是由sundararajan在2009年6月开发的一个开源项目，是一种动态跟踪分析一个运行中的Java应用程序的工具。
BTrace是一个为Java平台开发的安全、动态的追踪工具。BTrace动态地向目标应用程序的字节码注入追踪代码（字节码追踪），这些追踪字节码追踪代码使用Java语言表达，也就是BTrace的脚本。

## BTrace能做什么？

BTrace可以用来帮我们做运行时的JAVA程序分析，监控等等操作，BTrace也有一些使用上的限制，如：不能在脚本中新建类等。
Btrace是通过Attach API中提供的VirtualMachine.attach(PID)方法来获得要监控的JVM，然后使用VirtualMachine.loadAgent("*.jar")方法来加载jar文件。

## 特别注意

<span style="color:red">**BTrace植入过的代码，会一直在，直到应用重启为止。所以即使Btrace退出了，业务函数每次执行时都会执行Btrace植入的代码**</span>

## Btrace术语

**Probe Point(探测点)** 
追踪语句（或者一组追踪语句）被触发执行的“位置”或“事件”。也就是我们想要执行一些追踪语句的“位置”或“事件”。 
**Trace Actions or Actions（追踪动作）** 
probe被触发时，执行的追踪语句。 
**Action Methods（动作方法）** 
我的理解是定义追踪动作的方法，当然根据官方的说明这个方法应该是静态的。 
在静态方法中定义probe触发所调用的trace语句，那么这种定义了trace脚本的静态方法就是”动作方法”

## BTrace程序结构

一个BTrace程序是其实就是一个普通的java类，特别之处就是由一个或者多个被(public static void)组合修饰的方法并且这些方法被BTrace对应的annotations注解。注解用来指出被追踪程序的位置（probe point）。追踪动作须书写在静态方法体中，也就是action方法（可以有多个action方法）。

## BTrace约束

为了保证追踪动作是“只读”的（也就是这些动作不可以修改被追踪程序的状态）和有限度的（比如在固定时间里结束）。一个BTrace程序只允许完成一些指定的动作。下面是BTrace一些不可以完成的事情：

* 不能创建新的对象
* 不能创建新的数组
* 不能抛出异常
* 不能捕获异常
* 不能进行任何的实例函数或者静态函数 – 只有com.sun.btrace.BTraceUtils类中的静态函数或者BTrace程序自己声明的函数才可以被BTrace调用
* 不可以在目标程序的类，或者对象的静态或者实例级别的field进行赋值。但是，BTrace自身的类是可以给它的静态field进行赋值的
* 不能有outer，inner,嵌套的或者本地类。
* 不能有同步代码块或者同步的函数
* 不能有循环语句（for,while, do..while）
* 不能继承其它类（父类只能是java.lang.Object）
* 不能实现接口
* 不能包含断言(assert)语句
* 不能使用类字面值

这上面的种种限制可以通过一个配置改变：unsafe=true，在使用BTrace注解时修改该属性的默认值（false）为true，即@BTrace（unsafe=true）；也可以启动选项中显式声明-Dcom.sun.btrace.unsafe=true（响应也有-u参数）；现在你可以为所欲为了。<span style="color:red">**BUT，这样做之前最好考虑好风险并再三检查脚本，请斟酌使用！**</span>

## BTrace安装

[btrace](https://github.com/btraceio/btrace "btrace-gitbub") git下载地址
下载下来直接解压就可以使用

## 基本语法

```
btrace <pid> <btrace-script>脚本
```

btrace命令行工具运行命令如下：

```
btrace <options> <pid> <btrace source or .class file> <btrace arguments>
常用选项：
[-I <include-path>] [-p <port>] [-cp <classpath>]
```

参数说明：

```
where possible options include:
  --version             Show the version
  -v                    Run in verbose mode
  -o <file>             The path to store the probe output (will disable showing the output in console)
  -u                    Run in trusted mode
  -d <path>             Dump the instrumented classes to the specified path
  -pd <path>            The search path for the probe XML descriptors
  -classpath <path>     Specify where to find user class files and annotation processors
  -cp <path>            Specify where to find user class files and annotation processors
  -I <path>             Specify where to find include files
  -p <port>             Specify port to which the btrace agent listens for clients
  -statsd <host[:port]> Specify the statsd server, if any
```

+ **include-path** : 是一些用来查找头文件的目录。BTrace包含一个简单的预处理,支持# define,# + include和条件编译。它不像一个完整的C / c++预处理器–而是一个有用的子集。详见demo代码“ThreadBean.java”，如果没有显式的声明选项-I，Btrace跳过预处理程序调用步骤。
+ **port**： BTrace代理程序所侦听的端口，这是可选的选项。默认是2020
+ **classpath**: 是一些用来查找jar文件的目录。默认是当前目录”.”
+ **pid**：是要追踪目标程序id
+ **btrace-script**: 就是追踪程序本身。如果这是个java文件，那么提交前会进行编译。否则,它被认为已预编译(即它必须是一个类)并提交
+ **arguments**: 这是传递给BTrace程序的参数。BTrace程序可以通过内置的符号来引用这些参数，length是这些参数的个数。

在samples目录下有很多示例，并且有的跟踪很有用可直接使用，下来让我们编写一个脚本来看一下具体是怎么使用的

## BTrace的注解

### 方法注解

+ **@com.sun.btrace.annotations.OnMethod** 该注解可用来指定目标类，目标方法，以及目标方法里的“位置”。加了该注解后的操作方法会在对应的方法运行到指定的“位置”时被执行。这该注解中，目标类用“clazz”属性来指定，而目标方法用“method”属性来指定。”clazz”可以是类的全路径(比如java.awt.Component或者用两个反斜杠中间的正则表达式，参考例子NewComponent.java和Classload.java来看它们的用法，正则表达式可以匹配0个或多个目标类，这个时候多个类都会被进行动态指令更换。如/java\.awt\.+/匹配java.awt包下的所有类)。方法名也可以用这样的正则表达式 来匹配零个或者多个多个方法。参考例子MultiClass.java来查看用法。 还有一种方法来指定追踪类和函数。被追踪的类和函数可以用注解来指定。比如，如果”clazz”属性是@javax.jws.Webservice.那么BTrace会会把所有注解是这个的函数都进行动态指令更换。类似地，方法级别的注解也可以用来执行方法。参看例子WebServiceTracker.java来了解如何使用。可以把正则表达式和注解放在一起用，比如@/com\.acme\..+/可以匹配任何类，只要这个类的注解能跟那段正则表达式匹配即可。可以通过指定父类来匹配多个类名，比如+java.lang.Runnable就可以匹配所有实现了java.lang.Runnable这个接口的类。参考例子SubtypeTracer.java来看它的用法。
+ **@com.sun.btrace.annotations.OnTimer** 该注解可以用来执行那些需要周期性（间隔是毫秒）的追踪操作。参考Histogram.java来看它的用法。
+ **@com.sun.btrace.annotations.OnError** 该注解可以用来指定当任何异常抛出时需要执行的操作。被该注解修饰后的BTrace函数会在同一个BTrace类的其他操作方法抛出异常时执行。
+ **@com.sun.btrace.annotations.OnExit** 该注解用来执行党BTrace代码调用了exit(int)结束追踪会话后需要执行的操作。参考例子ProbeExit.java来了解如何使用。
+ **@com.sun.btrace.annotations.OnEvent** 该注解用来追踪函数与”外部”的事件关联起来。当BTrace客户端发送了一个“事件”后，该注解里的操作就会被执行。客户端发送的事件可能是由用户触发的（比如按下Ctrl-C）。事件的名字是个字符串，这样追踪操作就只会在对应的事件触发后被执行。到目标为止，BTrace命令行客户端会在用户按下Ctrl-C后发送事件，参考例子HistoOnEvent.java来了解用法。
+ **@com.sun.btrace.annotations.OnLowMemory** 该注解可以用来追踪特定内存阈值被用光的事件。参看例子MemAlerter.java了解用法。
+ **@com.sun.btrace.annotations.OnProbe** 该注解可以用来避免使用BTrace脚本的内部类。@OnProbe探测点被映射到一个或多个@OnMethod上。目前这个映射是通过一个XML探测描述文件类指定的（这个文件会被BTrace代理所使用）。参考例子SocketTracker1.java和对应的描述文件java.net.socket.xml.当运行这个例子时，xml文件需要放在目标JVM所有运行的目录下(或者修改btracer.bat中的probeDescPath选项来指向任意的xml文件)。
+ **@com.sun.btrace.annotations.Location**：该注解在一个traced/probed方法中指定一个特定的“位置”
+ **@com.sun.btrace.annotations.Simpled**：标记@OnMethod注解处理器采样。采样处理程序时并不是所有的事件将被追踪,只有一个统计样品与给定的意思。在默认情况下使用一种自适应采样。BTrace将增加或减少样品之间的调用数量保持平均时间窗口,因此减少整体的开销。

### 参数相关的注解

+ **@com.sun.btrace.annotations.Self**：该注解把一个参数标识为保留了目标函数所指向的this的值。参考例子AWTEventTracer.java和AllCalls1.java.
+ **@com.sun.btrace.annotations.Return**：该注解说明这个参数保存目标函数的返回值。参考例子Classload.java
+ **@com.sun.btrace.annotations.ProbeClassName**：所修饰的参数保留了探测类的类名 。参看AllMethods.java（有多个探测类）
+ **@com.sun.btrace.annotations.ProbeMethodName**：所修饰的参数保留了探测函数的函数名。参考WebServiceTracker.java（多个探测函数）
+ **@com.sun.btrace.annotations.TargetInstance**：修饰的参数保留了被调用的实例。参考例子AllCall2.java.
+ **@com.sun.btrace.annotations.TargetMethodOrField**：该注解修饰的参数保存了调用的函数名。参考AllCalls1.java 和AllCall2.java
+ **@com.sun.btrace.annotations.Duration**：探测方法参数标记为持续时间值的接收者，即目标方法执行的时间，单位纳秒。只是用带Location属性的@OnMethod，并且需要配合Kind.ERROR或者Kind.RETURN使用

### 无注解的参数

没有注解的`BTrace`探测函数参数是用来作签名匹配的，因为他们必须必须在固定的位置上出现。然而，它们可以和其他的注解的参数进行交换。如果一个参数的类型是_AnyType[]_，它就会“吃”掉所所有剩下的参数。没有注解的参数的具体含义与他们所在的位置有关：

|名称|作用|
|:--|:---|
|Kind.ARRAY_GET	|数组元素加载|
|Kind.ARRAY_SET	|数组元素存储|
|Kind.CALL	|方法调用|
|Kind.CATCH	|异常捕获|
|Kind.CHECKCAST	|checkcast|
|Kind.ENTRY	|方法进入。意指进入匹配probe点，跟你@Location设置的clazz和method没有任何关系|
|Kind.ERROR	|错误，异常没有捕获，返回|
|Kind.FIELD_GET	|field获取|
|Kind.FIELD_SET	|field设置|
|Kind.INSTANCEOF	|实例检测|
|Kind.LINE	|源代码行号|
|Kind.NEW	|创建新实例|
|Kind.NEWARRAY	|新的数组对象被创建|
|Kind.RETURN	|意指从某个匹配probe的方法中调用了匹配A class method的点，一定要和clazz,method配合使用。clazz和method的默认值为”“，所以不能被匹配|
|Kind.SYNC_ENTRY	|进入一个同步方法锁|
|Kind.SYNC_EXIT	|离开一个同步方法锁|
|Kind.THROW	|抛出异常|

### 字段相关的注解

+ **@com.sun.btrace.annotations.Export** BTrace字段使用该注解来说明它已经被映射到一个jvmstat计数器上。使用该注解，BTrace程序可以把追踪计数器暴露给外部的jvmstat客户端（比如jstat）。参考例子ThreadCounter.java
+ **@com.sun.btrace.annotations.Property**该注解可以把一个字段标识为一个MBean属性。如果一个BTrace类至少有一个静态的字段使用了该注解。那么一个MBean就会被创建并且注册到平台MBean服务器上。JMX客户端比如VisualVM，jconsole可以访问这个字段来查看BTrace的MBean。在把BTrace附加到目标程序上后，你可以把VisualVM或者jconsole也附加到同一个目标程序上来查看刚创建好的MBean属性。通过VisualVM或者jconsole,你可以通过MBeans tab页来查看BTrace相关的域，然后查看它们的值。参考例子ThreadCounterBean.java 和HistogramBean.java来了解用法
+ **@com.sun.btrace.annotations.TLS** BTrace字段使用该注解来说明它自己是一个线程本地字段（thread local field）.注意你只能在@OnMethod注解后的函数里访问这样的字段。每个Java线程都有一个这个字段的拷贝。为了让这样的方式能够工作，这个字段的类型只能是immutable（比如原始类型） 或者是cloneable （实现了Cloneable接口并且覆盖了clone()函数）的。这些线程本地字段可以被BTrace程序用来识别它是否在同一个线程里执行了多个探测操作。参考例子OnThrow.java和WebServiceTracker.java

### 类相关的注解

+ **@com.sun.btrace.annotations.DTrace**该注解用来把一小段D脚本（嵌在BTrace 的java类中）和BTrace程序关联起来。参考例子DTraceInline.java
+ **@com.sun.btrace.annotations.DTraceRef** 和上个注解一样，不同的是D脚本是在独立的文件中，不是嵌在java类中。
+ **@com.sun.btrace.annotations.BTrace**必须使用该注解来指定一个Java类是BTrace程序。BTrace编译器会强制查找该注解，BTrace代理也会检查这个是否有该注解。如果没有，则提示错误，并且不会执行。

## 脚本编写

```

package btrace;

import com.sun.btrace.BTraceUtils;
import com.sun.btrace.annotations.*;

@BTrace
public class UniqueIdMgrBtrace {
    @OnMethod(clazz = "com.atomikos.util.UniqueIdMgr", method = "get", location = @Location(Kind.RETURN))
    public static void onGet(@Return String result) {
        long millis = BTraceUtils.timeMillis();
        String threadName = BTraceUtils.Threads.name(BTraceUtils.currentThread());
        String str = BTraceUtils.strcat(BTraceUtils.str(millis), " - [");
        str = BTraceUtils.strcat(str, BTraceUtils.str(threadName));
        str = BTraceUtils.strcat(str, "] - com.atomikos.util.UniqueIdMgr.get()-->");
        str = BTraceUtils.strcat(str, BTraceUtils.str(result));
        BTraceUtils.println(BTraceUtils.str(str));
    }

    @OnMethod(clazz = "com.atomikos.icatch.imp.TransactionServiceImp", method = "setTidToTx")
    public static void onSetTidToTx(String tid) {
        long millis = BTraceUtils.timeMillis();
        String threadName = BTraceUtils.Threads.name(BTraceUtils.currentThread());
        String str = BTraceUtils.strcat(BTraceUtils.str(millis), " - [");
        str = BTraceUtils.strcat(str, BTraceUtils.str(threadName));
        str = BTraceUtils.strcat(str, "] - com.atomikos.icatch.imp.TransactionServiceImp.setTidToTx(");
        str = BTraceUtils.strcat(str, BTraceUtils.str(tid));
        str = BTraceUtils.strcat(str, ")");
        BTraceUtils.println(BTraceUtils.str(str));
    }
}
```

上面代码意思是在`com.atomikos.util.UniqueIdMgr.get()`方法上面进行跟踪返回值，要跟踪赶回值必须要加`@Location(Kind.RETURN))`,才能使用参数的`@Return`

如果要使用方法参数，可以在脚本方法上直接写跟踪的原始方法参数并且类型保持一样，例如：

```
package com.btrace;
//需要跟踪的类
public class RemoteClass {

    public String f1(String a, int b) {
        System.out.println(a + " " + b);
        return a;
    }
}

//btrace脚本
@BTrace public class HelloBtrace {

  @OnMethod(
    clazz="com.btrace.RemoteClass",
    method="f1"
  ) 
  public static void onF1() {
    println("Hello BTrace");
  }

  @OnMethod(
    clazz="com.btrace.RemoteClass",
    method="f1"
  ) 
  public static void onF2(String a,int b) {
    println(str(a));
    println(str(b));
    println("");
  }
}
```

## 注意事项

1. 脚本中方法参数需要跟原方法参数类型保持一致
2. 脚本中不允许使用除btrace之外的类，拼接字符串使用`BTraceUtils.strcat()`,打印使用`BTraceUtils.println()`,获取线程使用`BTraceUtils.Threads`
3. <span style="color:red">**BTrace植入过的代码，会一直在，直到应用重启为止。所以即使Btrace退出了，业务函数每次执行时都会执行Btrace植入的代码**</span>