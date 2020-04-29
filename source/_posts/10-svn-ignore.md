---
toc : true
title : "SVN设置文件忽略的多种方法"
description : "SVN设置文件忽略的多种方法"
tags : [
    "SVN",
	"ignore"
]
date : "2016-11-26 10:30:34"
categories : [
    "SVN"
]
menu : "main"
---


## 方法一：
在svn客户端（小乌龟），想设置忽略提交.class文件，通过 properties -> New -> Other 添加一个忽略的属性，，还是不行：部分屏蔽了，部分class还是在列表中

![svn1](/img/svn-ignore/1.jpg)

## 方法二：
在svn客户端（小乌龟）：Settings -> General -> Global ignore pattern 添加了一个 *.class就行了

![svn2](/img/svn-ignore/2.jpg)

## 方法三：
在 Eclipse 中点击菜单 window -> Preferences -> Team -> Ignored Resources

![svn3](/img/svn-ignore/3.jpg)
点击 Add Pattern… 按钮添加你要忽略的文件或目录

## 方法四：
在Eclipse的导航视图中，选中尚未加入版本控制的文件或目录，右键 -> Team -> 添加至SVN:ignore

![svn4](/img/svn-ignore/4.jpg)
![svn5](/img/svn-ignore/5.jpg)

## 方法五：
在资源管理器中，右键一个未加入版本控制文件或目录，并从弹出菜单选择TortoiseSVN -> Add to Ignore List，会出现一个子菜单，允许你仅选择该文件或者所有具有相同后缀的文件。

![svn6](/img/svn-ignore/6.jpg)
如果你想从忽略列表中移除一个或多个条目，右击这些条目，选择TortoiseSVN -> 从忽略列表删除。
