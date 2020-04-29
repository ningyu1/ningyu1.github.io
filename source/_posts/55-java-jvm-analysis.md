---
toc : true
title : "生产环境如何快速跟踪、分析、定位问题-Java"
description : "生产环境如何快速跟踪、分析、定位问题-Java"
tags : [
	"Java",
	"JVM",
	"CPU TOP",
	"Jstack",
	"Jmap",
	"JVM dump"
]
date : "2018-01-23 14:36:36"
categories : [
    "Java"
]
menu : "main"
---

我相信做技术的都会遇到过这样的问题，生产环境服务遇到宕机的情况下如何去分析问题？比如说JVM内存爆掉、CPU持续高位运行、线程被夯住或线程deadlocks，面对这样的问题，如何在生产环境第一时间跟踪分析与定位问题很关键。下来让我们看看通过如下步骤在第一时间分析问题。

# CPU占用较高场景

收集当前CPU占用较高的线程信息，执行如下命令：

```
top -H -p PID -b -d 1 -n 1 > top.log
或
top -H -p PID
```

结果如下：

![](/img/jvm-analysis/1.png)

上图显示的都是某一个进程内的线程信息，找到cpu消耗最高的线程id，再配合jstack来分析耗cpu的代码位置，那如何分析呢？

先执行jstack获取线程信息

```
jstack -l PID > jstackl.log
```

将PID（29978）转成16进制：0x751a，16进制转换工具很多可以在线随便搜索一个或者基本功好的自己计算。

打开jstackl.log，查找nid=0x751a的信息，这样就定位到了具体的代码位置，这里由于是安全原因我就不贴图了。

通过上面的步骤就可以轻松的定位那个线程导致cpu过高，当然也可以通过其他方式来定位，下面介绍一个快捷的方式

```
#线程cpu占用
#!/bin/bash

[ $# -ne 1 ] && exit 1

jstack $1 >/tmp/jstack.log

for cpu_tid in `ps -mp $1 -o THREAD,tid,time|sort -k2nr| sed -n '2,15p' |awk '{print$2"_"$(NF-1)}'`;do

cpu=`echo $cpu_tid | cut -d_ -f1`

tid=`echo $cpu_tid | cut -d_ -f2`

xtid=`printf "%x\n" $tid`

echo -e "\033[31m========================$xtid $cpu%\033[0m"

cat /tmp/jstack.log | sed -n -e "/0x$xtid/,/^$/ p"

#cat /tmp/jstack.log | grep "$xtid" -A15

done

rm /tmp/jstack.log
```

上述命令会以百分比的方式来显示每个线程的cpu消耗百分比，这里我就不贴图了，谁用谁知道。

# 内存消耗过高场景

收集当前活跃对象数据量信息，执行以下命令获取

```
jmap -histo:live pid > jmaplive.log
```

<span style="color:red">**ps. jmap -histo:live 数据可以多进行几次，比如说间隔几分钟输出一次，然后对比两个文件的差异可以看出gc回收的对象，如果多次结果没有差异并且gc频繁执行，证明剩余对象在引用无法gc回收，这时就需要对服务进行限流给服务喘气的机会。**</span>

或者收集dump信息，通常这种获取方式需要较长时间执行，并产生大容量的dump文件，我们会考虑逐步废掉通过这个文件来分析。执行以下命令获取

```
jmap -dump:file=./dump.mdump pid
```

dump文件通过MAT工具来进行内存泄漏分析。

# 线程、内存分析工具

上面说过通过jstack生成的线程文件是可以通过工具来直接打开可视化分析的，这里我推荐使用：tda（Thread Dump Analyzer）这个工具可以自行搜索下载。

通过jmap -dump生成的dump文件也是可以通过工具来进行可视化分析的，这里我推荐使用MAT（Memory Analysis Tools）它可以通过eclipse plugin的方式使用或者独立的下载安装包使用。









