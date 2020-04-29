---
toc : true
title : "构建Python多个虚拟环境来进行不同版本开发之神器-virtualenv"
description : "构建Python多个虚拟环境来进行不同版本开发之神器-virtualenv"
tags : [
	"virtualenv",
	"virtualenvwrapper",
	"python"
]
date : "2018-03-02 11:22:28"
categories : [
	"python"
]
menu : "main"
---


我们都知道`Python`的类库很多，但是大多支持的版本还是`Python2.x`系列，`Python3`支持的类库相对较少，因此我们在开发的时候经常还使用的`Python2`系列的版本，`Python3`对语法进行了比较大的重构，`Python3`中将一些`Python2`的模块名称做了修改，虽然兼容`Python2`但还是需要我们做一些处理来保证代码在不同`Python`版本中能够正常运作，如果我们想同时使用`Python2` 和 `Python3`，这个时候大家最常用的做法就是机器上配置多个版本，虽然可以解决问题但是配合多个项目的各种杂乱的包依赖情况，问题就变的非常复杂了，可能升级某一个第三方依赖库会对很多项目产生影响。

我们都知道在安装`Python`类库的时候它默认会安装到`Python`的目录下，有编程洁癖的人都会因此苦恼，因为它污染了`Python`的目录，并且在开发的时候不同的项目使用的类库差异也蛮大，为了使多个项目之间互相不影响，我们能不能根据项目来区分开`Python`环境目录？

当然可以，`virtualenv`就能帮助我们解决上面的苦恼，它是一个可以创建多个隔绝`Python`环境的工具，`virtualenv`可以创建一个包含所有必要的可执行的文件夹，用来使用`Python`工程所需要的包，同时还不污染`Python`的原安装目录。

这个工具简直就是给有开发洁癖的人送福音的。<scpan style="color:blue">*画外音：专业送快递*</span>

上面大致说了一下我们使用`virtualenv`的初衷，接下来让我们看一下`virtualenv`如何使用，在使用之前先正式的了解一下`virtualenv`

# 什么是virtualenv?

`Virtualenv`是一个用来创建独立的`Python`环境的工具

# 为什么我们需要一个独立的Python环境？

引用`virtualenv`的文档

```
virtualenv is a tool to create isolated Python environments.
The basic problem being addressed is one of dependencies and versions, and indirectly permissions. Imagine you have an application that needs version 1 of LibFoo, but another application requires version 2. How can you use both these applications? If you install everything into /usr/lib/python2.7/site-packages (or whatever your platform’s standard location is), it’s easy to end up in a situation where you unintentionally upgrade an application that shouldn’t be upgraded.
Or more generally, what if you want to install an application and leave it be? If an application works, any change in its libraries or the versions of those libraries can break the application.
Also, what if you can’t install packages into the global site-packages directory? For instance, on a shared host.
In all these cases, virtualenv can help you. It creates an environment that has its own installation directories, that doesn’t share libraries with other virtualenv environments (and optionally doesn’t access the globally installed libraries either).
```

上面这段话的意思大致是这样的，我们需要处理的基本问题是包的依赖、版本和间接权限问题。想象一下，你有两个应用，一个应用需要`libfoo`的版本1，而另一应用需要版本2。如何才能同时使用这些应用程序？如果您安装到的`/usr/lib/python2.7/site-packages`（或任何平台的标准位置）的一切，在这种情况下，您可能会不小心升级不应该升级的应用程序。或者更广泛地说，如果您想要安装一个应用程序并离开它呢?如果应用程序工作，其库中的任何更改或这些库的版本都可以破坏应用程序。另外，如果您不能将包安装到全局站点包目录中，该怎么办?例如，在共享主机上。在所有这些情况下，`virtualenv`可以帮助您。它创建了一个有自己的安装目录的环境，它不与其他`virtualenv`环境共享库(也不可能访问全局安装的库)。

简单地说，你可以为每个项目建立不同的/独立的Python环境，你将为每个项目安装所有需要的软件包到它们各自独立的环境中。

到这里我相信我们已经很清晰的知道了`virtualenv`是什么，能做什么，那接下来就让我们来用一用它。

# 使用virtualenv

## 安装

```
pip install virtualenv
```

<scpan style="color:blue">*画外音：pip安装非常简单，简直就是傻瓜式的*</span>

## 使用

`virtualenv`安装完毕后，可以通过运行下面的命令来为你的项目创建独立的`Python`环境：

```
mkdir my_project_dir
cd my_project_dir
virtualenv --distribute my_venv
# my_venv为虚拟环境目录名，目录名自定义
```

OK，执行成功，上面发生了什么？

它会在`my_project_dir`目录中创建一个文件夹（my_venv），包含了`Python`可执行文件，以及 `pip` 库的一份拷贝，这样就能安装其他包了。虚拟环境的名字（my_venv）可以是任意的；不写名字会使用当前目录创建。

我们再来看看输出：

```
1 New python executable in my_venv/bin/python2.7
2 Also creating executable in my_venv/bin/python
3 Installing Setuptools......done.
4 Installing Pip...........done.
```

`--distribute` 选项使`virtualenv`使用新的基于发行版的包管理系统而不是 `setuptools` 获得的包。 你现在需要知道的就是 `--distribute` 选项会自动在新的虚拟环境中安装 `pip` ，这样就不需要手动安装了。 当你成为一个更有经验的`Python`开发者，你就会明白其中细节。

当然还有很多参数配置，例如：-p参数指定Python解释器程序路径，这里就过多介绍了，通过help去查看。

到这里这个虚拟环境就创建好了，但是要真正使用还需要激活，通过如下命令激活。

```
my_project_dir\my_venv\Scripts\activate
```

激活后输出如下：

```
# window下
(my_venv) yourpath\venv\Scripts>

# linux下
(my_venv)[root@docker-x my_venv]#
```

从现在起，任何你使用pip安装的包将会放在 my_venv文件夹中，与全局安装的`Python`隔绝开，是不是很赞，想怎么装怎么装。

就像平常一样安装包，例如：

```
pip install flask
```

上面启用激活，有激活那就有停用，如果你在当前虚拟环境中暂时完成了工作，可以使用如下命令停用它：

```
my_project_dir\my_venv\Scripts\deactivate
```

这将会回到系统默认的`Python`解释器，包括已安装的库也会回到默认的。要删除一个虚拟环境，只需删除它的文件夹。（执行 `rm -rf venv` ）。

## 思考

让我们看看激活与停用`virtualenv`，调用python/pip命令有什么不一样。先停用`virtualenv`，如下：

```
[root@docker-x ~]# which python
/usr/bin/python
[root@docker-x ~]# which pip
/usr/local/bin/pip
```

让我们激活`virtualenv`后，再来一次！看看有什么不同。如下：
```
[root@docker-x ~]# which python
/usr/local/my_venv/bin/python

[root@docker-x ~]# which pip
/usr/local/my_venv/bin/pip
```

`virtualenv`拷贝了`Python`可执行文件的副本，并创建一些有用的脚本和安装了项目需要的软件包，你可以在项目的整个生命周期中安装/升级/删除这些包。 它也修改了一些搜索路径，例如`PYTHONPATH`，以确保：

1. 当安装包时，它们被安装在当前活动的`virtualenv`里，而不是系统范围内的`Python`路径。
2. 当import代码时，`virtualenv`将优先采取本环境中安装的包，而不是系统`Python`目录中安装的包。

还有一点比较重要，在默认情况下，所有安装在系统范围内的包对于`virtualenv`是可见的。这意味着如果你将`simplejson`安装在您的系统`Python`目录中，它会自动提供给所有的`virtualenvs`使用。这种行为可以被更改，在创建`virtualenv`时增加 `--no-site-packages` 选项,`virtualenv`就不会读取系统包，如下：

```
virtualenv my_venv --no-site-packages
```

# virtualenvwrapper

有的时候`virtualenv`也会带来一些问题，由于`virtualenv`的启动、停止脚本都在特定文件夹，可能一段时间后，你可能会有很多个虚拟环境散落在系统各处，你可能忘记它们的名字甚至忘记它的位置。怎么来管理`virtualenv`?

鉴于`virtualenv`不便于对虚拟环境集中管理，所以推荐直接使用`virtualenvwrapper`。 

`virtualenvwrapper`提供了一系列命令使得和虚拟环境工作变得便利。它把你所有的虚拟环境都放在一个地方。

## 安装

```
pip install virtualenvwrapper
pip install virtualenvwrapper-win　　#Windows使用该命令
```

<span style="color:blue">
*注意：安装virtualenvwrapper之前首先确保virtualenv已安装*
</span>

安装完成后，在~/.bashrc写入以下内容

```
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

#读入配置文件，立即生效
source ~/.bashrc
```

<span style="color:blue">
*说明：第一行：virtualenvwrapper存放虚拟环境目录，第二行：virtrualenvwrapper会安装到python的bin目录下，所以该路径是python安装目录下bin/virtualenvwrapper.sh*


## 使用

使用如下命令创建虚拟环境:

```
mkvirtualenv my_venv_py3
```

这样会在`WORKON_HOME`变量指定的目录下新建名为 my_venv_py3 的虚拟环境。

若想指定`Python`版本，可通过`--python`指定`Python`解释器

```
mkvirtualenv --python=/usr/local/python3.5.3/bin/python my_venv_py3
```

查看当前的虚拟环境目录

```
[root@docker-x ~]# workon
my_venv_py2
my_venv_py3
```

切换到虚拟环境

```
[root@docker-x ~]# workon my_venv_py3
(my_venv_py3) [root@docker-x ~]# 
```

退出虚拟环境

```
(my_venv_py3) [root@docker-x ~]# deactivate
[root@docker-x ~]# 
```

删除虚拟环境

```
rmvirtualenv my_venv_py3
```

到这里 `virtualenvs` 和 `virtualenvwrapper` 就讲完了，是不是 so easy！跟着步骤来，一切都是顺理成章的。而且功能也很强大，使`Python`的开发环境配置起来变得非常简单。尤其是扩展工具`virtualenvwrapper` 使得构建出来的虚拟环境可以更好的管理起来。感谢这个世界，世界和平，Keep Real！



