---
toc : true
title : "雪花算法-记录"
description : "雪花算法-记录"
tags : [
	"snowflake"
]
date : "2018-12-07 11:51:21"
categories : [
    "snowflake"
]
menu : "main"
---

最近看到了一篇分析雪花算法的文章还不错，然后整理了一下分享出来。

先来科普一下SnowFlake算法

# 算法原理

[Twitter Snowflake](https://github.com/twitter/snowflake) 生成的 unique ID 的组成 (由高位到低位):

41 bits: Timestamp (毫秒级)
10 bits: 节点 ID (datacenter ID 5 bits + worker ID 5 bits)
12 bits: sequence number
一共 63 bits (最高位是 0).

-----------------------------------
| 0(最高位预留) | 时间戳(41位) | 机器ID(10位) | 自增序列(12位) |
-----------------------------------

unique ID 生成过程:

* 10 bits 的机器号, 在 ID 分配 Worker 启动的时候，从一个 Zookeeper 集群获取 (保证所有的 Worker 不会有重复的机器号)；
* 41 bits 的 Timestamp: 每次要生成一个新 ID 的时候，都会获取一下当前的 Timestamp, 然后分两种情况生成 sequence number；
* 如果当前的 Timestamp 和前一个已生成 ID 的 Timestamp 相同 (在同一毫秒中)，就用前一个 ID 的 sequence number + 1 作为新的 sequence number (12 bits);
如果本毫秒内的所有 ID 用完，等到下一毫秒继续 (这个等待过程中, 不能分配出新的 ID)；
* 如果当前的 Timestamp 比前一个 ID 的 Timestamp 大, 随机生成一个初始 sequence number (12bits) 作为本毫秒内的第一个 sequence number；

41-bit的时间可以表示（1L<<41）/(1000L x 3600 x 24 x 365)=69年的时间，10-bit机器可以分别表示1024台机器。如果我们对IDC划分有需求，还可以将10-bit分5-bit给IDC，分5-bit给工作机器。这样就可以表示32个IDC，每个IDC下可以有32台机器，可以根据自身需求定义。12个自增序列号可以表示2^12个ID，理论上snowflake方案的QPS约为409.6w/s，这种分配方式可以保证在任何一个IDC的任何一台机器在任意毫秒内生成的ID都是不同的。

优缺点这里就不赘述了。

那我们继续看一个经典的Java版本的实现，这个在网上一搜一大把，官方原版的[Scala版本](https://github.com/twitter-archive/snowflake/blob/snowflake-2010/src/main/scala/com/twitter/service/snowflake/IdWorker.scala)

```
public class Snowflake {

	private static final Logger logger = LoggerFactory.getLogger(Snowflake.class);

	/**
	 * 机器ID
	 */
	private final long workerId;
	/**
	 * 时间起始标记点，作为基准，一般取系统的最近时间，默认2017-01-01
	 */
	private final long epoch = 1483200000000L;
	/**
	 * 机器id所占的位数（源设计为5位，这里取消dataCenterId，采用10位，既1024台）
	 */
	private final long workerIdBits = 10L;
	/**
	 * 机器ID最大值: 1023 (从0开始)
	 */
	private final long maxWorkerId = -1L ^ -1L << this.workerIdBits;
	/**
	 * 机器ID向左移12位
	 */
	private final long workerIdShift = this.sequenceBits;
	/** 
	 * 时间戳向左移22位(5+5+12)
	 */
	private final long timestampLeftShift = this.sequenceBits + this.workerIdBits;
	/** 
	 * 序列在id中占的位数
	 */
	private final long sequenceBits = 12L;
	/** 
	 * 生成序列的掩码，这里为4095 (0b111111111111=0xfff=4095)，12位
	 */
	private final long sequenceMask = -1L ^ -1L << this.sequenceBits;
	/**
	 * 并发控制，毫秒内序列(0~4095)
	 */
	private long sequence = 0L;
	/** 
	 * 上次生成ID的时间戳 
	 */
	private long lastTimestamp = -1L;
	
	private final int HUNDRED_K = 100_000;

	/**
	 * @param workerId 机器Id
	 */
	private Snowflake(long workerId) {
		if (workerId > this.maxWorkerId || workerId < 0) {
			String message = String.format("worker Id can't be greater than %d or less than 0", this.maxWorkerId);
			throw new IllegalArgumentException(message);
		}
		this.workerId = workerId;
	}
	
	/**
	 * Snowflake Builder
	 * @param workerId workerId
	 * @return Snowflake Instance
	 */
	public static Snowflake create(long workerId) {
		return new Snowflake(workerId);
	}
	
	/**
	 * 批量获取ID
	 * @param size 获取大小，最多10万个
	 * @return SnowflakeId
	 */
	public long[] nextId(int size) {
		if (size <= 0 || size > HUNDRED_K) {
			String message = String.format("Size can't be greater than %d or less than 0", HUNDRED_K);
			throw new IllegalArgumentException(message);
		}
		long[] ids = new long[size];
		for (int i = 0; i < size; i++) {
			ids[i] = nextId();
		}
		return ids;
	}

	/**
	 * 获得ID
	 * @return SnowflakeId
	 */
	public synchronized long nextId() {
		long timestamp = timeGen();

		// 如果上一个timestamp与新产生的相等，则sequence加一(0-4095循环);
		if (this.lastTimestamp == timestamp) {
			// 对新的timestamp，sequence从0开始
			this.sequence = this.sequence + 1 & this.sequenceMask;
			// 毫秒内序列溢出
			if (this.sequence == 0) {
				// 阻塞到下一个毫秒,获得新的时间戳
				timestamp = this.tilNextMillis(this.lastTimestamp);
			}
		} else {
			// 时间戳改变，毫秒内序列重置
			this.sequence = 0;
		}

		// 如果当前时间小于上一次ID生成的时间戳，说明系统时钟回退过这个时候应当抛出异常
		if (timestamp < this.lastTimestamp) {
			String message = String.format("Clock moved backwards. Refusing to generate id for %d milliseconds.", (this.lastTimestamp - timestamp));
			logger.error(message);
			throw new RuntimeException(message);
		}

		this.lastTimestamp = timestamp;
		// 移位并通过或运算拼到一起组成64位的ID
		return timestamp - this.epoch << this.timestampLeftShift | this.workerId << this.workerIdShift | this.sequence;
	}

	/**
	 * 等待下一个毫秒的到来, 保证返回的毫秒数在参数lastTimestamp之后
	 * @param lastTimestamp 上次生成ID的时间戳 
	 * @return
	 */
	private long tilNextMillis(long lastTimestamp) {
		long timestamp = timeGen();
		while (timestamp <= lastTimestamp) {
			timestamp = timeGen();
		}
		return timestamp;
	}

	/**
	 * 获得系统当前毫秒数
	 */
	private long timeGen() {
		return System.currentTimeMillis();
	}

}
```

那让我们看一下代码来理解一下算法的细节。

# 代码理解

我们从关键的代码段来理解，如下：

```
this.sequence = this.sequence + 1 & this.sequenceMask;

private final long maxWorkerId = -1L ^ -1L << this.workerIdBits;

return ((timestamp - this.epoch) << this.timestampLeftShift)
 | (this.workerId << this.workerIdShift)
 | this.sequence;
```
<span style="color:blue">*ps. 我这里取消了datacenterId，将datacenterId和workerid合并到workerIdBits*</span>

## 负数的二进制表示

在计算机中，负数的二进制是用补码来表示的。
假设我是用Java中的int类型来存储数字的，
int类型的大小是32个二进制位（bit），即4个字节（byte）。（1 byte = 8 bit）
那么十进制数字3在二进制中的表示应该是这样的：

```
00000000 00000000 00000000 00000011
// 3的二进制表示，就是原码
```

那数字-3在二进制中应该如何表示？
我们可以反过来想想，因为-3+3=0，
在二进制运算中把-3的二进制看成未知数x来求解，
求解算式的二进制表示如下：

```
   00000000 00000000 00000000 00000011 //3，原码
+  xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx //-3，补码
-----------------------------------------------
   00000000 00000000 00000000 00000000
```

反推x的值，3的二进制加上什么值才使结果变成00000000 00000000 00000000 00000000？：

```
   00000000 00000000 00000000 00000011 //3，原码                         
+  11111111 11111111 11111111 11111101 //-3，补码
-----------------------------------------------
 1 00000000 00000000 00000000 00000000
```

反推的思路是3的二进制数从最低位开始逐位加1，使溢出的1不断向高位溢出，直到溢出到第33位。然后由于int类型最多只能保存32个二进制位，所以最高位的1溢出了，剩下的32位就成了（十进制的）0。

补码的意义就是可以拿补码和原码（3的二进制）相加，最终加出一个“溢出的0”

以上是理解的过程，实际中记住公式就很容易算出来：

补码 = 反码 + 1
补码 = （原码 - 1）再取反码
因此-1的二进制应该这样算：

```
00000000 00000000 00000000 00000001 //原码：1的二进制
11111111 11111111 11111111 11111110 //取反码：1的二进制的反码
11111111 11111111 11111111 11111111 //加1：-1的二进制表示（补码）
```

具体对位运算以及二进制的计算理解可以看看这篇文章[https://blog.csdn.net/cj2580/article/details/80980459](https://blog.csdn.net/cj2580/article/details/80980459)