---
toc : true
title : "npm registry太慢？怎么办？使用nrm"
description : "npm registry太慢？怎么办？使用nrm"
tags : [
    "npm",
	"nrm"

]
date : "2017-09-29 14:16:36"
categories : [
    "npm",
	"nrm"
]
menu : "main"
---

转载自：[http://cnodejs.org/topic/5326e78c434e04172c006826](http://cnodejs.org/topic/5326e78c434e04172c006826)

开发的npm registry 管理工具 [nrm](https://github.com/Pana/nrm),  能够查看和切换当前使用的registry, 最近NPM经常 down 掉, 这个还是很有用的哈哈

## Install

```
$ npm install -g nrm
```

## Example

```
$ nrm ls

* npm ---- https://registry.npmjs.org/
  cnpm --- http://r.cnpmjs.org/
  eu ----- http://registry.npmjs.eu/
  au ----- http://registry.npmjs.org.au/
  sl ----- http://npm.strongloop.com/
  nj ----- https://registry.nodejitsu.com/
```

```
$ nrm use cnpm //switch registry to cnpm

    Registry has been set to: http://r.cnpmjs.org/
```

## cmd

```
nrm help // show help
nrm list // show all registries
nrm use cnpm // switch to cnpm
nrm home // go to a registry home page
```

## Registries

* [npm](https://www.npmjs.org/)
* [cnpm](http://cnpmjs.org/)
* [strongloop](http://strongloop.com/)
* [european](http://npmjs.eu/)
* [australia](http://npmjs.org.au/)
* [nodejitsu](https://www.nodejitsu.com/)

