---
toc : true
title : "Python项目生成requirements.txt的多种方式，用于类库迁移必备"
description : "Python项目生成requirements.txt的多种方式，用于类库迁移必备"
tags : [
	"pip",
	"freeze",
	"pipreqs",
	"python"
]
date : "2018-03-09 14:19:54"
categories : [
    "python"
]
menu : "main"
---

我相信任何软件程序都会有依赖的类库，尤其现在开源如此的火爆，很多轮子可以拿来直接使用不再需要自己再去开发（拿来主义者），这样大大的提高开发效率。`NPM`就是轮子最多的地方，哈哈！开个玩笑！

我们做开发时为何需要对依赖库进行管理？当依赖类库过多时，如何管理类库的版本？

我相信大家都知道怎么回答这个问题，为了更加规范管理项目结构，提高开发效率所以我们需要对依赖库进行管理，不管使用任何开发语言，如今都有依赖库的管理工具。

例如：`Java`有`Maven`、`Gradle`，`JS`有`NPM`，`Python`有`pip`、`easy_install`，`Linux`有`apt-get`、`yun` 等。

我们这里就对`Python`的依赖库管理来进一步说一说。

`Python`提供通过`requirements.txt`文件来进行项目中依赖的三方库进行整体安装导入。

那首先让我们看一下`requirements.txt`的格式

```
requests==1.2.0
Flask==0.10.1
```

`Python`安装依赖库使用`pip`可以很方便的安装，如果我们需要迁移一个项目，那我们就需要导出项目中依赖的所有三方类库的版本、名称等信息。

接下来就看`Python`项目如何根据`requirements.txt`文件来安装三方类库

# 方法一：pip freeze

```
pip freeze > requirements.txt
```

`pip freeze`命令输出的格式和`requirements.txt`文件内容格式完全一样，因此我们可以将`pip freeze`的内容输出到文件`requirements.txt`中。在其他机器上可以根据导出的`requirements.txt`进行包安装。

如果要安装`requirements.txt`中的类库内容，那么你可以执行

```
pip install -r requirements.txt
```

<span style="color:blue">*注意：`pip freeze`输出的是本地环境中所有三方包信息，但是会比`pip list`少几个包，因为`pip`，`wheel`，`setuptools`等包，是自带的而无法(`un`)`install`的，如果要显示所有包可以加上参数`-all`，即`pip freeze -all`*</span>

# 方法二：pipreqs

使用`pipreqs`生成`requirements.txt`

首先先安装`pipreqs`

```
pip install pipreqs
```

使用`pipreqs`生成`requirements.txt`

```
pipreqs requirements.txt
```

<span style="color:blue">*注意：`pipreqs`生成指定目录下的依赖类库*</span>

# 上面两个方法的区别？

使用`pip freeze`保存的是当前`Python`环境下所有的类库，如果你没有用`virtualenv`来对`Python`环境做虚拟化的话，类库就会很杂很多，在对项目进行迁移的时候我们只需关注项目中使用的类库，没有必要导出所有安装过的类库，因此我们一般迁移项目不会使用`pipreqs`，`pip freeze`更加适合迁移整个`python`环境下安装过的类库时使用。

<span style="color:blue">*不知道`virtualenv`是什么或者不会使用它的可以查看：[《构建Python多个虚拟环境来进行不同版本开发之神器-virtualenv》](https://ningyu1.github.io/site/post/63-python-virtualenv/)*</span>

使用`pipreqs`它会根据当前目录下的项目的依赖来导出三方类库，因此常用与项目的迁移中。

这就是`pip freeze`、`pipreqs`的区别，前者是导出`Python`环境下所有安装的类库，后者导出项目中使用的类库。



