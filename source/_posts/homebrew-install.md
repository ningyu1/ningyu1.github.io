---
toc : true
title : "解决安装Homebrew过程遇到的问题"
description : "在国内安装Homebrew的时候经常会遇到各种错误，本篇就是解决所有问题，让你可以成功安装Homebrew"
tags : [
	"Homebrew",
	"trouble shooting"
]
date : "2021-01-18 14:07:26"
categories : [
    "Homebrew",
    "tool"
]
menu : "main"
---


本篇主要讲解在国内安装Homebrew遇到的各种错误如何解决，让你可以轻松安装Homebrew，用mac的同学应该对Homebrew并不陌生，这里简单介绍一下Homebrew

#Homebrew简介

引用 [官方](https://brew.sh/) 的一句话：Homebrew是Mac OS 不可或缺的套件管理器。

Homebrew是一款Mac OS平台下的软件包管理工具，拥有安装、卸载、更新、查看、搜索等很多实用的功能。简单的一条指令，就可以实现包管理，而不用你关心各种依赖和文件路径的情况，十分方便快捷。

所以它是Mac必备神器Homebrew。

#安装时遇到的错误一

安装的命令很简单如下
```shell script
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

当你在国内运行上面命令时会遇到下面的错误

```shell script
curl: (7) Failed to connect to raw.githubusercontent.com port 443: Connection refused
```

这是因为被墙了，如果你是科学上网的话，就使用你上网的神器来代理，这块我想说的就是使用代理收费的肯定比免费的要好一些，如果可以的话花钱买一个，毕竟天天都要使用。

那么如何代理？使用下面命令

假设我的代理http端口是：1087，socket是：869

```shell script
export https_proxy=http://127.0.0.1:1087 http_proxy=http://127.0.0.1:1087 all_proxy=socks5://127.0.0.1:869
```

ps. 将端口替换成你自己的代理端口，输入上面的命令代理只会在本次打开的`terminal`生效。

设置完代理之后再运行安装命令就不会看到无法连接raw.githubusercontent.com，紧接着提示需要你输入电脑密码，输入密码后它会提示你如下信息：

```shell script
==> This script will install:
/usr/local/bin/brew
/usr/local/share/doc/homebrew
/usr/local/share/man/man1/brew.1
/usr/local/share/zsh/site-functions/_brew
/usr/local/etc/bash_completion.d/brew
/usr/local/Homebrew

Press RETURN to continue or any other key to abort
```

输入回车直接安装即可。


#安装时遇到的错误二

这里需要注意一个问题，它会去github上下载Homebrew代码进行安装。代码现在完后安装他会卡在某一个地方，比如说我这里卡在

```shell script
==> /usr/bin/sudo /usr/sbin/chown jiuye:admin /usr/local/Homebrew
==> Downloading and installing Homebrew...
HEAD is now at 48e44870e Merge pull request #10334 from SeekingMeaning/rubocop-spec-descriptions

```

长时间卡在这里不动，我直接`Control + C`退出，因为源码已经下载安装完成，其余的不知道为啥卡在这里，但是它已经安装成功了。

退出后运行`brew -v`测试一下是否可用，如果可以使用就证明安装成功。


#使用brew安装工具包遇到的错误三

比如说我们安装wget的时候会遇到如下问题，它会长时间卡如下地方

```shell script
Updating Homebrew...
```

如果长时间卡在升级homebrew的话，我们可以尝试`Control + C`退出homebrew升级，这个时候它会跳过升级直接安装我们需要的包直到安装结束，如下所示：

```shell script
MacBook-Pro:~ jiuye$ brew install wget
==> Downloading https://homebrew.bintray.com/bottles-portable-ruby/portable-ruby-2.6.3_2.yosemite.bottle.tar.gz
######################################################################## 100.0%
==> Pouring portable-ruby-2.6.3_2.yosemite.bottle.tar.gz
Updating Homebrew...

^C==> Downloading https://homebrew.bintray.com/bottles/gettext-0.20.2_1.mojave.bot
==> Downloading from https://d29vzk4ow07wi7.cloudfront.net/52067198cab528f05fdc0
######################################################################## 100.0%
==> Downloading https://homebrew.bintray.com/bottles/libunistring-0.9.10.mojave.
==> Downloading from https://d29vzk4ow07wi7.cloudfront.net/1d0c8e266acddcebeef3d
######################################################################## 100.0%
```

到目前为止我们就成功的安装和测试了Homebrew，本次主要收录我在使用过程中遇到的问题，如果后续安装其他包遇到其他问题的话，我也会持续的更新它收录在一起。

#特殊说明
到最后要说明一点，Homebrew在安装软件包的时候，它会将软件包安装到独立目录，并将其文件软链接至 /usr/local ，通过`ls -l`查看

```shell script
ls -l /usr/local/bin/

lrwxr-xr-x  1 xxx  xxx        32  1 18 13:33 wget -> ../Cellar/wget/1.20.3_2/bin/wget
-rwxr-xr-x  1 xxx  xxx       123  3  7  2019 wish
-rwxr-xr-x  1 xxx  xxx       123  3  7  2019 wish8.6
lrwxr-xr-x  1 xxx  xxx        39  1 18 13:33 xgettext -> ../Cellar/gettext/0.20.2_1/bin/xgettext
```


