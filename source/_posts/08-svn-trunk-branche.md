---
toc : true
title : "分支(branche)开发，主干(trunk)发布"
description : "分支(branche)开发，主干(trunk)发布"
tags : [
    "SVN",
	"trunk",
	"branche"
]
date : "2016-12-20 14:32:41"
categories : [
    "SVN"
]
menu : "main"
---


主干，分支分开开发模式在使用的时候要注意，主干是不做任何代码修改，只负责merge，修改全在分支上，不管是新功能的开发分支，还是修复bug的分支，如果线上有紧急bug修复，要先容trunk上拉一个bugfix分支出来，修改提交然后在merge到主干上去 ，打包测试发包。

图示：

![svn1](/img/svn/1.jpg)

**注意事项：**
**本地修改的代码不要藏在本地 不提交，如果发现没有地方可以提交，提交会影响版本发布，那就是主干、分支开发模式使用不当，请及时调整**
