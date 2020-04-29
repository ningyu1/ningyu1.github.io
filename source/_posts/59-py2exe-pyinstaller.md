---
toc : true
title : "如何将Python脚本打包成可执行文件？"
description : "如何将Python脚本打包成可执行文件"
tags : [
	"python",
	"py2exe",
	"pyinstaller",
	"bbFreeze",
	"cx_Freeze",
	"py2app"
]
date : "2018-02-07 11:57:49"
categories : [
    "python"
]
menu : "main"
---

我们有时候经常会使用`python`写一些小工具，在`Linux`环境下可以很方便运行，因为`Linux`默认都会有`python`环境，我们只需要添加`python`脚本依赖的类库即可执行。但是有的时候我们需要把小工具给到一些麻瓜去用的时候就会出现一些问题，他们大多是在`Windows`上运行工具，那就必须要先准备`python`的可运行环境才行，这就给麻瓜们带来了使用成本，我们能否将`python`脚本打包成windows下可执行文件呢？

接下来让我们先了解一下`python`有哪些类库可以帮助我们解决这个问题。

这是一个来自**Freezing Your Code**的统计

|Solution|Windows|Linux|OS X|Python 3|License|One-file mode|Zipfile import|Eggs|pkg_resources support|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|bbFreeze|yes|yes|yes|no|MIT|no|yes|yes|yes|
|py2exe|yes|no|no|yes|MIT|yes|yes|no|no|
|pyInstaller|yes|yes|yes|yes|GPL|yes|no|yes|no|
|cx_Freeze|yes|yes|yes|yes|PSF|no|yes|yes|no|
|py2app|no|no|yes|yes|MIT|no|yes|yes|yes|

我们能看到有很多类库都可以解决我们的问题，其中`pyInstaller`、`cx_Freeze`、`bbFreeze`都不错，pkg_resources新版的`pyInstaller`貌似是支持的。

我们这里选用`pyInstaller`尝试一下，因为它各方面支持的是最好的。

# PyInstaller原理介绍

`PyInstaller`其实就是把`python`解析器和脚本以及脚本的依赖库打包成一个可执行的文件，这和编译成真正的机器码是两回事，所以通过`PyInstaller`打包成一个可执行文件可能不会提高运行效率，相反可能会降低运行效率，但是它带来的好处就是在运行者的机器上不用安装`python`和你的脚本依赖的库。在`Linux`操作系统下，它主要用的`binutil`工具包里面的`ldd`和`objdump`命令。

`PyInstaller`输入你指定的的脚本，首先分析脚本所依赖的其他脚本，然后去查找，复制，把所有相关的脚本收集起来，包括`Python`解析器，然后把这些文件放在一个目录下，再打包进一个可执行文件里。

这样就可以直接发布输出整个文件夹里面的文件，或者生成可执行文件。你只需要告诉用户，你的App是自我包含的，不需要安装其他包，或某个版本的`Python`，就可以直接运行。

但是需要注意的是，`PyInstaller`打包的执行文件，只能在和打包机器系统同样的环境下运行。它不具备可移植性，若需要在不同系统上运行，就必须针对不同平台进行打包。


# 安装PyInstaller

网络情况可以的话使用`pip`安装还是很方便的。

```
pip install pyinstaller
```

如果网络不稳定，尤其在天朝访问墙外站点是很痛苦的，我们还可以通过下载源码包来安装。

```
# 在源码包的根目录下执行
python setup.py install
```

安装完成后，检查安装版本。

```
pyinstaller --version
```

# 使用PyInstaller进行打包

`pyinstaller`的语法

```
pyinstaller [options] script [script ...] | specfile
```

具体命令如何使用可以通过help或[官方文档](http://pythonhosted.org/PyInstaller/usage.html)去查询具体的用法。

我这里只说几个注意的点。

`-F, --onefile	Create a one-file bundled executable.`创建一个可执行文件

`-w, --windowed, --noconsole`去除黑框

```
# A path to search for imports (like using PYTHONPATH). Multiple paths are allowed, separated by ‘:’, or use this option multiple times

-p DIR, --paths DIR
```

设置一个可搜索的入口路径，怎么理解呢？如果不指定这个参数打包出来的文件只能在生成它的目录下运行，如果打包时指定参数为`-p .`打包出来的文件可以放在任意路径下运行，如下示例：

```
pyinstaller -w -F -p . your.py
```

# 参考资料

* [Freezing Your Code](http://docs.python-guide.org/en/latest/shipping/freezing/#comparison-of-freezing-tools)
* [PyInstaller官方WIKI](http://pythonhosted.org/PyInstaller/usage.html)
* [PyInstaller Github](https://github.com/pyinstaller/pyinstaller)

到这里`PyInstaller`就简单介绍完毕，感兴趣的可以试一试，我以前使用的是`py2exe`，其实`py2exe`也蛮好只不过它需要创建一个`py`脚本来把需要打包的脚本包含进去，用起来没有`PyInstaller`方便，希望这个简单的入门可以帮助到需要的朋友。

Keep Real！