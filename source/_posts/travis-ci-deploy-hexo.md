---
toc : true
title : "使用Travis CI部署Hexo"
description : "使用Travis CI部署Hexo"
tags : [
	"travis-ci",
	"hexo"
]
date : "2020-04-30 12:19:26"
categories : [
    "travis-ci"
]
menu : "main"
---





今天说一下使用travis ci来部署hexo，在说这个之前呢要先提几个概念，CI/CD（是一种通过在应用开发阶段引入自动化来频繁向客户交付应用的方法）。

什么是CI？ 持续集成，Continuous Integration，简称 CI

什么是CD？ 持续交付，Continuous Deployment，简称CD

我们都知道软件开发写代码只是其中的一部分，写出代码后需要构建（build）、测试（test）、发布（deploy）。

这些都是比较按部就班的操作，所以有很多工具化的支持，为了提高软件开发效率，构建和测试的工具有很多，我们最熟知的是[jenkins](https://jenkins.io/)，相信很多人都用过，还有很多如[gitlab-ci](https://about.gitlab.com/features/gitlab-ci-cd/)、[travis-ci](https://travis-ci.org/)、等。



今天我们就说一下[travis-ci](https://travis-ci.org/)的简单使用，刚好我的blog每次都要编译然后提交到github，刚好用它做一个演示。



### Travis CI的介绍

Travis CI

是CI / CD生态系统中比较常见的名号之一，最初设定为开源项目，并在多年扩展之后转为闭源项目。它专注于CI工作，通过自动化测试和警报系统提高构建过程的效能。

#### 它有什么作用？

Travis-CI允许用户在部署代码时对代码进行快速测试。它支持代码大小变更，可识别构建与测试中发生的一切变更。检测到变更后，Travis CI可以提供有关变更是否成功的反馈。

开发人员可以使用Travis CI对运行时进行观察，并行运行多项测试，并将该工具与Slack、HipChat以及Email等集成，从而通过多种渠道获取问题或构建失败通知。

Travis CI支持容器构建，并支持Linux Ubuntu和OSX。您可以在不同的编程语言中使用它，例如Java，C＃，Clojure，GO，Haskell，Swift，Perl等等。其具备一份相对有限的第三方集成列表，但由于关注重点在于CI而非CD，因此其可能解决不了您的实际问题。



# 使用Travsi CI发布Hexo



我的blog使用的是[Hexo](<https://hexo.io/>)，它有丰富的模板可以选择，支持markdown写文章再构建生成静态html，所以当时就选用了它。



在做之前我们需要准备一些东西，如下：



首先我们要在github上创建一个repository，给这个repository创建两个分支，我这里使用master作为静态html分支，blog-source作为博客源码分支。

_ps. 分支名称都随意，有人喜欢用master作为源码分支，gh-pages作为静态html分支，都可以请随意。_



去github上获取accesstoken，可以去<https://github.com/settings/tokens>获取，生成一个token（generate new token），token的scope范围看自己的需求选择，我这里选择的是repo下全部。

生成的token记得自己先保存起来，因为刷新页面后你就再也看不到它了，如果忘记了那就去重新生成一个（regenerate token）



在blog库的blog-source分支中添加.travis.yml

```yaml
language: node_js
node_js: 10.16.3
install:
  - npm install
script: bash ./deploy.sh
branches:
  only:
    - blog-source
notifications:
  email: false
```

hexo采用nodejs开发，所以这里语言选择nodejs，我这里选择nodejs版本是10.16.3，因为高版本nodejs下hexo生成的静态文件有问题，如果是其他的程序可以使用standard。



install阶段执行npm安装依赖。



script阶段执行一个外部脚本

```shell
#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e

# 生成静态文件
hexo generate

# 进入生成的文件夹
cd ./public

#创建.nojekyll 防止Github Pages build错误
touch .nojekyll

git init
git add -A
git commit -m "deploy"
git push -f "https://${access_token}@github.com/ningyu1/blog.git" master:master

cd -
```

脚本中先试用`hexo -g`生成静态html文件，文件生成在当前目录下的public文件夹。

进入到public文件夹下执行git命令，这里需要注意的是使用`git push -f`强制推送，如果没有设置`git user.name`和`git user.email`的话提交的用户是`Travis Ci User`

_ps. 这里特殊说明一下`${access_token}`，这里使用travis ci的运行时环境变量，放到运行时环境变量相对安全一些，避免别人拿到我的accesstoken做一些坏事情，哈哈。_



打开[travis-ci](https://travis-ci.org/)登录，这里可以使用github三方登录，添加一个github仓库，travis跟github集成还是非常紧密和方便的，添加仓库可以直接读取github上的仓库，在列表里面找到blog打开使用travis，如图一。

![图一](/img/travis-ci/1.png)



进入dashbord查看刚才添加的库信息，选择More options->Settings，添加Environment Variables

创建一个access_token的环境变量，可以选择那些branch使用，DISPLAY VALUE IN BUILD LOG是控制构建日志中是否要输出变量的值，为了安全起见建议不用开启，如图二

![图二](/img/travis-ci/2.png)



一切准备就绪之后提交并推送代码到github仓库，这样travis会接收到github的push event事件，可以去More options->Requests中查看接收到的请求信息，如图三

![图三](/img/travis-ci/3.png)



如果没有啥特殊情况看构建日志就可以看到成功信息。



这里我遇到了一个问题，我使用hexo只支持10.x一下的nodejs版本，刚开始使用的standard标准版本的nodejs，然后看到构建日志中输出的版本如下

```
$ node --version
v14.0.0
$ npm --version
6.14.4
$ nvm --version
0.35.3
```

导致hexo生成的html文件都是0 byte，果断的降低了nodejs版本就好了。








