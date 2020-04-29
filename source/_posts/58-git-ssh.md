---
toc : true
title : "Git SSH Key settings and passphrase reset"
description : "Git SSH Key settings and passphrase reset"
tags : [
	"git",
	"github",
	"ssh key",
	"passphrase"
]
date : "2018-01-30 16:10:20"
categories : [
    "git"
]
menu : "main"
---

在使用github仓库的时候我们经常会看到`clone`有两种方式:`https`、`ssh`，`https`的方式使用起来非常简单但是每次在`pull`、`push`的时候需要输入密码，一两次还可以忍受但是作为常态是有点崩溃的，这个时候我们可以使用`ssh`的方式，`ssh`的好处就是在`pull`、`push`的时候可以使用密码也可以不使用密码，但是前提是要设置好`ssh key`，如果你是`Repository`的管理员那很好设置，如果不是管理员那就老老实实的使用`https`的方式，下来我们就说一下使用`ssh`遇到的问题。

# 修改用户主目录（home）

当出现下图问题时：

![](/img/git-ssh/1.png)

是说明你的.ssh目录设置的有问题，关于用户主目录（home）的问题，一般windows机器安装完git后home都会是`C:\Users\用户名`这种目录，但是打开Git bash时它无法识别home目录使用到了其他莫名其妙的目录（有的时候会是不存在的目录或是网络盘符），在这个时候就需要变更home目录，变更的方法如下：

环境：windows

## Git version 1.x系列

如果是Git version 1.x系列，打开profile文件，文件位置：`$\Git\etc\profile`（$替换成你的盘符）。
在profile中找到：`HOME="$(cd "$HOME" ; pwd)"`这个位置，在前面增加你想变成的home目录，例如：

```
# normalize HOME to unix path
HOME="C:\Users\用户名"
HOME="$(cd "$HOME" ; pwd)"

export PATH="$HOME/bin:$PATH"

export GNUPGHOME=~/.gnupg
```

当修改好之后，重启Git bash即可，输入`cd ~/.ssh`，会进入你设置好的目录，在这个目录下生成相关的配置文件，如：.ssh、.gnupg、.bash_history、.gitconfig等，如果以前已经有这些文件可以copy到这个目录下直接使用。

## Git version 2.x系列

如果是Git version 2.x系列，请设置环境变量，增加HOME的环境变量，目录为：`C:\Users\用户名`（你想设置的目录），随后重启Git bash即可，输入`cd ~/.ssh`，会进入你设置好的目录。

按照上面步骤修改好之后，出现下图所示就证明修改完成了。如：

![](/img/git-ssh/2.png)

# ssh key设置

输入`cd ~/.ssh`进入home目录使用如下如下方法生成ssh key

* 可以在Git bash中使用`ssh-keygen`生成ssh key
* 还可以使用eclipse的ssh2工具生成，操作如下：Window -> Preferences -> General -> Network Connections -> SSH -> Key Management -> Generate RSA Key
* 还可以使用TortoiseGit的PuTTY Key Generator工具生成。

方法有很多，生成好的private key用文本编辑器打开复制出来，粘贴到git hub的settings中即可，操作如下：github -> Settings -> SSH and GPG keys -> New SSH key，起个名字粘贴key然后保存即可。

# 每次都输入passphrase问题

当我们在第一次`git clone`的时候会提示`Enter passphrase`，这个时候如果输入了密码，那以后`pull`、`push`都需要输入这个密码，就像我下图这样：

![](/img/git-ssh/3.png)

我们使用ssh就是图个方便不想输入密码，出现这个问题怎么办呢？

在第一次`git clone`的时候提示`Enter passphrase`的时候不要输入密码，直接回车即可，如果输入了密码那就需要重置密码才能解决这个问题。

## 重置passphrase

打开Git bash使用如下命令重置密码

```
ssh-keygen -p
```

输入后根据下图提示操作：

![](/img/git-ssh/4.png)

这样就完成了重置密码为空的操作了，后面再`pull`、`push`的时候都不会再提示输入密码。


