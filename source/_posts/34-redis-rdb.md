---
toc : true
title : "Redis RDB文件格式全解析"
description : "Redis RDB文件格式全解析"
zhuan : true
tags : [
    "Redis",
	"RDB"

]
date : "2017-10-09 14:30:36"
categories : [
    "Redis",
    "技术"
]
menu : "main"
---

# 点评

这篇文章作为对RDB理解的教程文章，对RDB文件的原理理解有助于进行Redis高阶应用的设计与开发。

文章转自：http://blog.nosqlfan.com/html/3734.html
作者：@nosqlfan

RDB文件是Redis持久化的一种方式，Redis通过制定好的策略，按期将内存中的数据以镜像的形式转存到RDB文件中。那么RDB文件内部格式是什么样的呢，Redis又做了哪些工作让RDB能够更快的dump和加载呢，下面我们深入RDB文件，来看一看其内部结构。
首先我们来看一个RDB文件的概况图：

```
----------------------------# RDB文件是二进制的，所以并不存在回车换行来分隔一行一行.
52 45 44 49 53              # 以字符串 "REDIS" 开头
30 30 30 33                 # RDB 的版本号，大端存储，比如左边这个表示版本号为0003
----------------------------
FE 00                       # FE = FE表示数据库编号，Redis支持多个库，以数字编号，这里00表示第0个数据库
----------------------------# Key-Value 对存储开始了
FD $length-encoding         # FD 表示过期时间，过期时间是用 length encoding 编码存储的，后面会讲到
$value-type                 # 1 个字节用于表示value的类型，比如set,hash,list,zset等
$string-encoded-key         # Key 值，通过string encoding 编码，同样后面会讲到
$encoded-value              # Value值，根据不同的Value类型采用不同的编码方式
----------------------------
FC $length-encoding         # FC 表示毫秒级的过期时间，后面的具体时间用length encoding编码存储
$value-type                 # 同上，也是一个字节的value类型
$string-encoded-key         # 同样是以 string encoding 编码的 Key值
$encoded-value              # 同样是以对应的数据类型编码的 Value 值
----------------------------
$value-type                 # 下面是没有过期时间设置的 Key-Value对，为防止冲突，数据类型不会以 FD, FC, FE, FF 开头
$string-encoded-key
$encoded-value
----------------------------
FE $length-encoding         # 下一个库开始，库的编号用 length encoding 编码
----------------------------
...                         # 继续存储这个数据库的 Key-Value 对
FF                          ## FF：RDB文件结束的标志
```

下面我们对上面的内容进行详细讲解

## Magic Number

第一行就不用讲了，REDIS字符串用于标识是Redis的RDB文件

## 版本号

用了4个字节存储版本号，以大端（big endian）方式存储和读取

## 数据库编号

以一个字节的0xFE开头，后面存储数据库的具体编号，数据库的编号是一个数字，通过 “Length Encoding” 方式编码存储，“Length Encoding” 我们后面会讲到。

## Key-Value值对

值对包括下面四个部分
1. Key 过期时间，这一项是可有可无的
2. 一个字节表示value的类型
3. Key的值，Key都是字符串，通过 “Redis String Encoding” 来保存
4. Value的值，通过 “Redis Value Encoding” 来根据不同的数据类型做不同的存储

## Key过期时间

过期时间由 0xFD 或 0xFC开头用于标识，分别表示秒级的过期时间和毫秒级的过期时间，后面的具体时间是一个UNIX时间戳，秒级或毫秒级的。具体时间戳的值通过“Redis Length Encoding” 编码存储。在导入RDB文件的过程中，会通过过期时间判断是否已过期并需要忽略。

## Value类型

Value类型用一个字节进行存储，目前包括以下一些值：

* 0 = “String Encoding”
* 1 = “List Encoding”
* 2 = “Set Encoding”
* 3 = “Sorted Set Encoding”
* 4 = “Hash Encoding”
* 9 = “Zipmap Encoding”
* 10 = “Ziplist Encoding”
* 11 = “Intset Encoding”
* 12 = “Sorted Set in Ziplist Encoding”

## Key

Key值就是简单的 “String Encoding” 编码，具体可以看后面的描述


## Value

上面列举了Value的9种类型，实际上可以分为三大类

* type = 0, 简单字符串
* type 为  9, 10, 11 或 12, value字符串在读取出来后需要先解压
* type 为 1, 2, 3 或 4, value是字符串序列，这一系列的字符串用于构建list，set，hash 和 zset 结构

## Length Encoding

上面说了很多 Length Encoding ，现在就为大家讲解。可能你会说，长度用一个int存储不就行了吗？但是，通常我们使用到的长度可能都并不大，一个int 4个字节是否有点浪费呢。所以Redis采用了变长编码的方法，将不同大小的数字编码成不同的长度。

1. 首先在读取长度时，会读一个字节的数据，其中前两位用于进行变长编码的判断
2. 如果前两位是 0 0，那么下面剩下的 6位就表示具体长度
3. 如果前两位是 0 1，那么会再读取一个字节的数据，加上前面剩下的6位，共14位用于表示具体长度
4. 如果前两位是 1 0，那么剩下的 6位就被废弃了，取而代之的是再读取后面的4 个字节用于表示具体长度
5. 如果前两位是 1 1，那么下面的应该是一个特殊编码，剩下的 6位用于标识特殊编码的种类。特殊编码主要用于将数字存成字符串，或者编码后的字符串。具体见 “String Encoding”

这样做有什么好处呢，实际就是节约空间：

1. 0 – 63的数字只需要一个字节进行存储
2. 而64 – 16383 的数字只需要两个字节进行存储
3. 16383 - 2^32 -1 的数字只需要用5个字节（1个字节的标识加4个字节的值）进行存储

## String Encoding

Redis的 String Encoding 是二进制安全的，也就是说他没有任何特殊分隔符用于分隔各个值，你可以在里面存储任何东西。它就是一串字节码。
下面是 String Encoding 的三种类型

1. 长度编码的字符串
2. 数字替代字符串：8位，16位或者32位的数字
3. LZF 压缩的字符串

## 长度编码字符串

长度编码字符串是最简单的一种类型，它由两部分组成，一部分是用 “Length Encoding” 编码的字符串长度，第二部分是具体的字节码。

## 数字替代字符串

上面说到过 Length Encoding 的特殊编码，就在这里用上了。所以数字替代字符串是以 1 1 开头的，然后读取这个字节剩下的6 位，根据不同的值标识不同的数字类型：

* 0 表示下面是一个8 位的数字
* 1 表示下面是一个16 位的数字
* 2 表示下面是一个32 位的数字

## LZF压缩字符串

和数据替代字符串一样，它也是以1 1 开头的，然后剩下的6 位如果值为4，那么就表示它是一个压缩字符串。压缩字符串解析规则如下：

1. 首先按 Length Encoding 规则读取压缩长度 clen
2. 然后按 Length Encoding 规则读取非压缩长度
3. 再读取第二个 clen
4. 获取到上面的三个信息后，再通过LZF算法解码后面clen长度的字节码

## List Encoding

Redis List 结构在RDB文件中的存储，是依次存储List中的各个元素的。其结构如下：

1. 首先按 Length Encoding 读取这个List 的长度 size
2. 然后读取 size个 String Encoding的值
3. 然后再用这些读到的 size 个值重新构建 List就完成了

## Set Encoding

Set结构和List结构一样，也是依次存储各个元素的

## Sorted Set Encoding

todo

## Hash Encoding

1. 首先按 Length Encoding 读出hash 结构的大小 size
2. 然后读取2×size 个 String Encoding的字符串（因为一个hash项包括key和value两项）
3. 将上面读取到的2×size 个字符串解析为hash 和key 和 value
4. 然后将上面的key value对存储到hash结构中

## Zipmap Encoding

参见本站之前的文章：Redis zipmap内存布局分析