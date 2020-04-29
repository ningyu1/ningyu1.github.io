---
toc : true
title : "为什么手机浏览器打开word、excel文件部分文件能预览，部分文件不能预览？"
description : "为什么手机浏览器打开word、excel文件部分文件能预览，部分文件不能预览？"
tags : [
	"word-xml"
]
date : "2018-08-09 09:48:00"
categories : [
    "case-analysis"
]
menu : "main"
---

最近公司合同项目中有很多附件是excel和word的格式，这些文件有用户直接导入的，也有程序自动生成的，合同项目中有结合钉钉来做工作流，所以会有pc端和钉钉移动端的互动。

## 问题现象

pc端的附件列表可以正常的下载word、excel文件，并且可以成功的打开，但是当流程流转到钉钉时，在钉钉审批的时候可以通过连接跳转h5来显示附件列表，项目的功能设计初衷是可以在手机端打开预览word、excel文件。

但是发现了奇怪的问题，部分word可以在钉钉中显示，部分word无法显示，例如下图所示：

![](/img/word-xml/1.png)

我们的期望效果如下图所示：

![](/img/word-xml/2.png)

## 问题分析

我们分别使用手机浏览器（safari）、postman、微信内嵌浏览器、qq内嵌浏览器分别测试无法正常预览的word链接

手机浏览器、微信内嵌浏览器、qq内嵌浏览器均无法打开

使用postman下载在移动端无法打开的word链接，返回的是一段xml，如下：

```

<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<?mso-application progid="Word.Document"?>
<pkg:package xmlns:pkg="http://schemas.microsoft.com/office/2006/xmlPackage"><pkg:part pkg:name="/_rels/.rels"
....
```

这是个什么鬼？是word的xml格式，问题原因就在这里手机浏览器无法识别word的xml格式，因此再次尝试excel

excel使用的是poi生成直接写的是二级制格式，没有使用xml格式，因此excel是可以在移动端打开预览的。

询问开发word是如何生成的？

生成过程是这样的：使用word编辑好模版，然后另存为xml格式，导入到系统中去，通过FreeMarker替换内容，再将xml写到fastdfs中去后缀给成 '.doc' ,这样下载下来使用office word可以直接打开xml格式的来进行无损渲染。

## 解决方案

询问业务是否必须要使用word格式文件？我的理解合同项目大多都是给用户只读的文件，建议使用pdf来做，使用jasper生成word模版，通过jasper的java api直接生成pdf，合同后期还要考虑添加水印，pdf更加方便一些。

建议使用pdf来替换word，如果非要使用word，建议生成word二进制格式来替换xml格式，除非不考虑移动端渲染可以使用xml格式的word。

目前java生成word的方式有如下六种方式：

1. Jacob是Java-COM Bridge的缩写，它在Java与微软的COM组件之间构建一座桥梁。使用Jacob自带的DLL动态链接库，并通过JNI的方式实现了在Java平台上对COM程序的调用。DLL动态链接库的生成需要windows平台的支持。该方案只能在windows平台实现，是其局限性。
2. Apache POI包括一系列的API，它们可以操作基于MicroSoft OLE 2 Compound Document Format的各种格式文件，可以通过这些API在Java中读写Excel、Word等文件。他的excel处理很强大，对于word还局限于读取，目前只能实现一些简单文件的操作，不能设置样式。
3. Java2word是一个在java程序中调用 MS Office Word 文档的组件(类库)。该组件提供了一组简单的接口，以便java程序调用他的服务操作Word 文档。 这些服务包括： 打开文档、新建文档、查找文字、替换文字，插入文字、插入图片、插入表格，在书签处插入文字、插入图片、插入表格等。填充数据到表格中读取表格数据 ，1.1版增强的功能： 指定文本样式，指定表格样式。如此，则可动态排版word文档。是一种不错的解决方案。
4. iText是著名的开放源码的站点sourceforge一个项目，是用于生成PDF文档的一个java类库。通过iText不仅可以生成PDF或rtf的文档，而且可以将XML、Html文件转化为PDF文件。功能强大。
5. JSP输出样式，该方案实现简单，但是处理样式有点缺陷，简单的导出可以使用。
6. 用XML做就很简单了。Word从2003开始支持XML格式，大致的思路是先用office2003或者2007编辑好word的样式，然后另存为xml，将xml翻译为FreeMarker模板，最后用java来解析FreeMarker模板并输出Doc。经测试这样方式生成的word文档完全符合office标准，样式、内容控制非常便利，打印也不会变形，生成的文档和office中编辑文档完全一样。

## 总结

伴随着手机的兴起，不管是传统行业还是互联网行业对系统都有在移动端使用的要求，不管是从用户体验上还是从移动系统兼容性以及浏览器兼容性上都会遇到各种问题，当然也有工具可以解决这些问题，例如：RN、flutter都可以很好的解决系统兼容问题，vue.js、angularjs都可以很好的解决浏览器兼容问题，而且这些都有大厂的支持，关于以上的问题这种解决方法并不是最好的，但是可以做为一种参考，重点是对问题的总结，只要解决问题的方法符合自己的业务场景我个人认为就是正（有）确（效）的方法，如果有更好的方式可以在下放留言一起讨论。

