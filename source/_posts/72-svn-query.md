---
toc : true
title : "Subversion库如何全文检索代码？"
description : "Subversion库如何全文检索代码？"
tags : [
	"svn",
	"subversion",
	"svnquery"
]
date : "2018-03-23 10:44:53"
categories : [
    "svn"
]
menu : "main"
---

现在是`Git`流行的年代，在`Git`的套件里想要全文检索代码也有很多方案，`Git`也支持命令直接检索代码，但是当使用`svn`的用户代码检索应该如何处理呢？

在回答前面问题之前我们还要搞清楚另外一个问题，我们为什么要检索代码？

有的时候我们想从所有的代码库去寻找使用相同方法的代码，常规做法就是`checkout`下来所有的项目，然后通过`IDE`工具去关联检索使用到某个方法的代码，但是这样做比较耗费时间而且当项目过多`IDE`不一定能扛得住。还有的时候我们想从规范角度去`check`开发人员写的代码是否有违规的或者有问题的，就可以通过检索去寻找，当然规范的`check`有更好的工具，可以使用`scm`工具`sonar`去`check`代码它整合了很多`check`模版。

鉴于上面种种的原因对代码做检索还是很有必要的，接下来我们就说一下使用`svn`时如何全文检索代码。

我们可以先说一个思路，把代码灌入`elasticsearch`、`lucene`、`solr`，然后通过ui去搜索这是一条可行的路子。

这两天发现了一个工具`svnquery`很好用，它使用`ASP.net`开发，采用`Lucene`生成索引，提供`GUI`和`WEB`工具通过索引文件来检索代码。

[svnquery官网](http://svnquery.tigris.org/servlets/ProjectProcess?pageID=o0dpdE)

它提供三个程序，一个`svnindex`用于通过`svn`库生成索引目录

```
SvnIndex.exe %aciton% %index_path% %svn_path% -u 用户名 -p 密码
```

<span style="color:blue">*ps. `action`包括`create`、`update`，更新和修改*</span>

执行后会生成一个索引目录，可以通过`svnfind`工具可以选择索引目录来进行代码搜索，`svnfind`是一个`GUI`工具。

![](/img/svnquery/1.png)

还可以通过`SvnWebQuery`来进行代码搜索，`SvnWebQuery`是一个`.NET`的`web`程序需要放入`IIS`服务器来使用

![](/img/svnquery/2.png)

<span style="color:blue">*引用官网的两张图*</span>

唯一的缺点就是需要一个库一个库的生成索引，没有批量生成`svn`路径下所有有权限的库，如果有这个功能我个人觉得就完美了。

好了工具介绍到这里，如果有用`svn`的想对代码进行检索的可以使用这个工具。