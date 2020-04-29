---
toc : true
title : "RESTful开发日期类型字段如何正确传递"
description : "RESTful开发日期类型字段如何正确传递"
tags : [
	"restful",
	"date-convert"
]
date : "2019-02-12 15:30:21"
categories : [
    "restful"
]
menu : "main"
---

RESTful开发时经常会遇到参数传入日期类型及返回的日期类型值，日期和时间戳如果没有适当和一致地处理，就会给人带来头痛的问题，我这里建议大家使用统一格式化的时间字符串`yyyy-MM-dd HH:mm:ss`，为什么建议这个呢？这样看起来比较直观，前后端联调起来比较高效。

下面我们就细说一下日期类型的参数将如何处理。

# GET方法时参数传入日期类型该如何处理

举例

url如下：

```
http://localhost:8081/test/time_get?time=2018-07-09 10:38:57
```

Controller代码：

```
import java.util.Date;

@RequestMapping(value = "/time_get", method = RequestMethod.GET)
@ResponseBody
public Response<Date> time_get(Date time) {
    logger.info("time:{}", time);
    return Response.createResponse(time);
}
```

在这种情况下日期参数是无法成功的传入到controller方法里，会爆出如下的异常：

```
org.springframework.core.convert.ConversionFailedException: Failed to convert from type java.lang.String to type java.util.Date for value '2018-07-09 10:38:57'; nested exception is java.lang.IllegalArgumentException
at org.springframework.core.convert.support.ObjectToObjectConverter.convert(ObjectToObjectConverter.java:81) ~[spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 at org.springframework.core.convert.support.ConversionUtils.invokeConverter(ConversionUtils.java:35) ~[spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 at org.springframework.core.convert.support.GenericConversionService.convert(GenericConversionService.java:178) ~[spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 at org.springframework.beans.TypeConverterDelegate.convertIfNecessary(TypeConverterDelegate.java:161) ~[spring-beans-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 at org.springframework.beans.TypeConverterDelegate.convertIfNecessary(TypeConverterDelegate.java:93) ~[spring-beans-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 at org.springframework.beans.TypeConverterSupport.doConvert(TypeConverterSupport.java:64) ~[spring-beans-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 ... 43 common frames omitted
Caused by: java.lang.IllegalArgumentException: null
 at java.util.Date.parse(Date.java:615) ~[na:1.7.0_45]
 at java.util.Date.<init>(Date.java:272) ~[na:1.7.0_45]
 at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method) ~[na:1.7.0_45]
 at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:57) ~[na:1.7.0_45]
 at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45) ~[na:1.7.0_45]
 at java.lang.reflect.Constructor.newInstance(Constructor.java:526) ~[na:1.7.0_45]
 at org.springframework.core.convert.support.ObjectToObjectConverter.convert(ObjectToObjectConverter.java:76) ~[spring-core-4.0.0.RELEASE.jar:4.0.0.RELEASE]
 ... 48 common frames omitted
```

那如何解决上面的问题？使用`@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")`加到日期参数之前，像下面那样使用一样。

Controller代码：

```
import java.util.Date;
 
@RequestMapping(value = "/time_get", method = RequestMethod.GET)
@ResponseBody
public Response<Date> time_get(@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") Date time) {
    logger.info("time:{}", time);
    return Response.createResponse(time);
}
```

<span style="color:blue">*提示：年月日：pattern="yyyy-MM-dd"，年月日时分秒：pattern="yyyy-MM-dd HH:mm:ss"*</span>

请求体：

```
GET /test/time_get1?time=2018-07-09 11:31:00 HTTP/1.1
Host: localhost:8081
```

后端接收到的信息，debug截图：

![](/img/restful-date-convert/1.png)


# POST方法时参数传入日期类型该如何处理

当使用`@RequestBody`接受一个`VO`对象时`@DateTimeFormat`就会失效，因为我们走的是`Json`序列化与反序列化，`@DateTimeFormat`只会生效与`object`序列化、反序列化。如果使用的`Spring`可以自定义`messageConvert`或者增强`MappingJackson2HttpMessageConverter`中的`ObjectMapper`

代码如下：

```
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurationSupport;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;

@Configuration
public class WebConfig extends WebMvcConfigurationSupport {
    @Override
    protected void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
        List<HttpMessageConverter<?>> messageConverters = new ArrayList<HttpMessageConverter<?>>();
        addDefaultHttpMessageConverters(messageConverters);
        for (int i = 0; i < messageConverters.size(); i++) {
            HttpMessageConverter<?> mc = messageConverters.get(i);
            if (mc instanceof MappingJackson2HttpMessageConverter) {
                ObjectMapper objectMapper = new ObjectMapper();
                //当json中属性在反序列化时，javabean中没有找到属性就忽略，如果FAIL_ON_UNKNOWN_PROPERTIES=true找不到属性会报错
                objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
                //设置序列化、反序列化时日期类型的格式
                objectMapper.setDateFormat(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss"));
                ((MappingJackson2HttpMessageConverter) mc).setObjectMapper(objectMapper);
            }
            converters.add(mc);
        }
    }
}

```

<span style="color:blue">*注意：使用Jackson进行json序列化反序列化，默认可以处理`yyyy-MM-dd`这个格式，但是反序列化后的时间会差8小时*</span>

通过上面对json序列化反序列化的配置后日期参数处理就变的简单了，效果如下。


Controller代码：

```

@RequestMapping(value = "/time_post", method = RequestMethod.POST)
@ResponseBody
public Response<Date> time_post(@RequestBody TestVo vo) {
    logger.info("time:{}", vo.getTime());
    return Response.createResponse(vo.getTime());
}
```

VO代码：

```
public class TestVo implements Serializable {
    private static final long serialVersionUID = 7435595656552442126L;
    private Date time;
    public Date getTime() {
        return time;
    }
    public void setTime(Date time) {
        this.time = time;
    }
}
```

<span style="color:blue">*提示：`VO`中无需使用`@DateTimeFormat`，就是一个普通的javabean即可*</span>

请求体：

```
POST /test/time_post HTTP/1.1
Host: localhost:8081
Content-Type: application/json
{
    "time":"2018-07-09 15:31:00"
}
```

后端接收到的信息，debug截图

![](/img/restful-date-convert/2.png)

# PUT方法时参数传入日期类型该如何处理

如果put传参方式与get一样在方法上直接传参（`url?time=2018-07-09 10:38:57`），那参考get请求参数处理方式即可

如果put传参方式与post一样使用`@RequestBody`传入json格式数据，那么参考post请求参数处理方式即可

请求体：

```
PUT /test/time_put HTTP/1.1
Host: localhost:8081
Content-Type: application/json
{
    "time":"2018-07-09 15:31:00"
}
```

后端接收到的信息，debug截图

![](/img/restful-date-convert/3.png)

前面都说的是request时日期格式处理方式，那么我们继续说一下response时日期格式如何处理。

# Response中日期格式该如何处理

SpringMVC使用`@ResponseBody`时，日期格式默认显示为时间戳，不管方法直接返回Date类型、或者VO类型时，时间格式都一样返回时间戳，例如这样。

请求体：

```
POST /test/time_post1 HTTP/1.1
Host: localhost:8081
Content-Type: application/json
{
    "time":"2018-07-09"
} 
```

响应体：

```

{
    "code": "",
    "message": "",
    "items": {
        "time": 1531094400000
    }
}
```

那如果我们要以字符串格式返回呢，那该如何处理？

方法一增加统一的`messageConvert`处理：

如果使用的spring可以自定义`messageConvert`或者增强`MappingJackson2HttpMessageConverter`中的`ObjectMapper`

代码在[POST方法时参数传入日期类型该如何处理](#POST方法时参数传入日期类型该如何处理)这个章节

方法二通过`@JsonFormat`注解处理：

请在`VO`对象的date字段上加上`@JsonFormat(pattern="yyyy-MM-dd HH:mm:ss",timezone = "GMT+8")`,例如下面代码：

VO代码：

```
public class TestVo implements Serializable {
    private static final long serialVersionUID = 7435595656552442126L;
 
    @JsonFormat(pattern="yyyy-MM-dd HH:mm:ss",timezone = "GMT+8")
    private Date time;
    public Date getTime() {
        return time;
    }
    public void setTime(Date time) {
        this.time = time;
    }
}
```

<span style="color:blue">*注意：@JsonFormat(pattern="yyyy-MM-dd HH:mm:ss",timezone = "GMT+8") ，即可将json返回的对象为指定的类型。*</span>

返回日期格式使用的是"yyyy-MM-dd HH:mm:ss"样式字符串示例：

请求体：

```
POST /test/time_post1 HTTP/1.1
Host: localhost:8081
Content-Type: application/json
{
    "time":"2018-07-09 15:31:00"
} 
```

响应体：

```
{
    "code": "",
    "message": "",
    "items": {
        "time": "2018-07-09 15:31:00"
    }
}
```

# 日期格式处理规范

这里有的人喜欢使用时间戳，有的人喜欢使用统一格式化的时间字符串`yyyy-MM-dd HH:mm:ss`，我个人的建议使用后者，因为这样比较直观调试交流起来也比较方便。

使用哪种没有对错，其实就是一种规范，统一规范可以提升协作效率，因此我建议的规范如下：

* 前端传入日期格式：yyyy-MM-dd HH:mm:ss，例如：2018-07-09 12:55:12（不使用时间戳，前后双方联调时查看起来更加友好）
* 后端返回日期格式：yyyy-MM-dd HH:mm:ss，例如：2018-07-09 12:55:12（不使用时间戳，前后双方联调时查看起来更加友好）
* 后端json序列化、反序列化框架：定义任何一种高效的json工具都行，例如：Fastjson、Gson、Jackson lib
* 序列化、反序列化日期格式规范：pattern="yyyy-MM-dd HH:mm:ss",timezone = "GMT+8"，除特出场景可以使用pattern="yyyy-MM-dd",timezone = "GMT+8"
* 不要随意自定义convert处理日期格式以及其他特殊格式转换，应该交由基础框架组或架构组统一在框架层面解决，对业务开发透明，或者在有些小公司由Leader或高开来担当。

这些都是我个人摸爬滚打多年码出来的心得体会，说的不好还请见谅，希望可以帮助有需要的人。




