---
toc : true
title : "推荐一个性能测试工具包（适用于单元测试）"
description : "推荐一个性能测试工具包（适用于单元测试）"
tags : [
	"java",
	"test"
]
date : "2018-01-11 16:52:36"
categories : [
    "java",
	"test"
]
menu : "main"
---

给大家推荐一个做单元测试非常好用的性能测试工具包，contiperf，很方便的进行并发压力测试

* pom引用

```
<!-- 单元测试 -->
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.7</version>
    <scope>test</scope>
</dependency>
<!-- 性能测试 -->
<dependency>
    <groupId>org.databene</groupId>
    <artifactId>contiperf</artifactId>
    <version>2.1.0</version>
    <scope>test</scope>
</dependency>
```

* 使用示例

```
/**
 * <功能描述>
 *
 * @author ningyu
 * @date 2017年10月24日 下午2:40:58
 */
public class MyPerfTest {
     
    private IRedisSequenceService sequenceService;
     
    @Rule
    public ContiPerfRule i = new ContiPerfRule();
    @Before
    public void init() {
        ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("test-spring-context.xml");
        sequenceService = (IRedisSequenceService) context.getBean("redisSequenceService");
    }
     
    @Test
    @PerfTest(threads=10, invocations=10000)//threads并发线程数量，invocations总调用次数,还有其他参数可以设置查看文档或者源码
    public void test() {
        try {
            long res = sequenceService.nextSeq("TEST_NINGYU");
        System.out.println(Thread.currentThread().getName()+":"+res);
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}
```
