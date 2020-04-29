---
toc : true
title : "Json序列化、反序列化支持泛型，Dubbo对泛型参数方法进行反射调用"
description : "Json序列化、反序列化支持泛型，Dubbo对泛型参数方法进行反射调用"
tags : [
	"json",
	"gson",
	"dubbo",
	"GenericService"
]
date : "2018-03-13 15:31:53"
categories : [
    "dubbo",
	"json"
]
menu : "main"
---


最近在对Dubbo接口进行反射调用时，遇到了参数类型较为复杂的情况下，使用反射方式无法调用的问题。

由于Dubbo使用了proxy代理对象，因此在反射上调用是存在一定的问题，从反射对象上获取的方法和参数类型可能会导致无法正常的调用。

首先先让我们看一个复杂参数的接口定义

```
public String testMethod(Map<String,ResourceVo> map, List<Map<String,ResourceVo>> list) throws BizException;
```

## Gson反序列化复杂类型

在对参数进行反序列化时，内部的类型容易丢失，我们可以使用gson的Type进行反序列化得到正确的参数值，让我们看一下gson反序列化的两个方法

```
  /**
   * This method deserializes the specified Json into an object of the specified class. It is not
   * suitable to use if the specified class is a generic type since it will not have the generic
   * type information because of the Type Erasure feature of Java. Therefore, this method should not
   * be used if the desired type is a generic type. Note that this method works fine if the any of
   * the fields of the specified object are generics, just the object itself should not be a
   * generic type. For the cases when the object is of generic type, invoke
   * {@link #fromJson(String, Type)}. If you have the Json in a {@link Reader} instead of
   * a String, use {@link #fromJson(Reader, Class)} instead.
   *
   * @param <T> the type of the desired object
   * @param json the string from which the object is to be deserialized
   * @param classOfT the class of T
   * @return an object of type T from the string. Returns {@code null} if {@code json} is {@code null}.
   * @throws JsonSyntaxException if json is not a valid representation for an object of type
   * classOfT
   */
  public <T> T fromJson(String json, Class<T> classOfT) throws JsonSyntaxException {
    Object object = fromJson(json, (Type) classOfT);
    return Primitives.wrap(classOfT).cast(object);
  }

 /**
   * This method deserializes the specified Json into an object of the specified type. This method
   * is useful if the specified object is a generic type. For non-generic objects, use
   * {@link #fromJson(String, Class)} instead. If you have the Json in a {@link Reader} instead of
   * a String, use {@link #fromJson(Reader, Type)} instead.
   *
   * @param <T> the type of the desired object
   * @param json the string from which the object is to be deserialized
   * @param typeOfT The specific genericized type of src. You can obtain this type by using the
   * {@link com.google.gson.reflect.TypeToken} class. For example, to get the type for
   * {@code Collection<Foo>}, you should use:
   * <pre>
   * Type typeOfT = new TypeToken&lt;Collection&lt;Foo&gt;&gt;(){}.getType();
   * </pre>
   * @return an object of type T from the string. Returns {@code null} if {@code json} is {@code null}.
   * @throws JsonParseException if json is not a valid representation for an object of type typeOfT
   * @throws JsonSyntaxException if json is not a valid representation for an object of type
   */
  @SuppressWarnings("unchecked")
  public <T> T fromJson(String json, Type typeOfT) throws JsonSyntaxException {
    if (json == null) {
      return null;
    }
    StringReader reader = new StringReader(json);
    T target = (T) fromJson(reader, typeOfT);
    return target;
  }
```

让我们测试一下复杂接口参数在使用这两个方法反序列化会有什么不同

```
String json = "{\"name\":\"name\",\"value\":{\"service\":\"test1\",\"url\":\"test\",\"action\":\"GET\",\"enabled\":true,\"isPublic\":false,\"appId\":8,\"menuId\":30001}}";
Class clazz = Map.class;
Map map = gson.fromJson(json, clazz);
```

上面代码反序列化后的map对象实际是`com.google.gson.internal.LinkedTreeMap<K, V>`，这个是gson中自定义的Map实现类，而且内部的对象也都是`LinkedTreeMap`，当我们换成HashMap时，返回的结果都是`HashMap`，但是我们的方法上使用的是`Map<String,ResourceVo>`，如何才能反序列化得到这个类型的对象呢？让我们看一下使用Type后的情况。

```
String json = "{\"name\":\"name\",\"value\":{\"service\":\"test1\",\"url\":\"test\",\"action\":\"GET\",\"enabled\":true,\"isPublic\":false,\"appId\":8,\"menuId\":30001}}";
Type type = new TypeToken<ResourceVo>(){}.getType();
Map<ResourceVo> map = gson.fromJson(json, type);
```

通过使用TypeToken生成的Type对象可以得到`Map<String,ResourceVo>`这个类型的实例，但是当我们在反射调用方法时，由于不知道参数是什么类型，也不能够import自定义的对象来使用`TypeToken`来获取type对象，那我们应该怎么做呢？接着往下看

<span style="color:blue">ps.类型：List&#60;ResourceVo>和List&#60;Map&#60;Object,ResourceVo>>这样的类型一样使用Type来进行反序列化</span>

```
String json = "{\"name\":\"name\",\"value\":{\"service\":\"test1\",\"url\":\"test\",\"action\":\"GET\",\"enabled\":true,\"isPublic\":false,\"appId\":8,\"menuId\":30001}}";
Class clazz = Class.forName("com.package.JavaBean");
String methodName = "testMethod";
Method[] methods = clazz.getMethods();
for (Method m : methods) {
	if (m.getName().equals(methodName)) {
		Type[] paramTypes = m.getGenericParameterTypes();
		for (int j = 0; j < paramTypes.length; j++) {
			gson.fromJson(json, paramTypes[j]);
		}
	}
}
```

可以通过`method.getGenericParameterTypes()`获取参数的`Type`对象。

<span style="color:blue">但是需要注意的是，当使用`Proxy`代理对象通过上面的方式获取的`Type`对象全都是`java.lang.Class`</span>

那如何解决代理对象获取的`Type`不正确的问题呢？

正确的做法就是放弃通过`Proxy`对象来进行反射，使用`Class.forName`获取`Class`对象进行反射。

可以通过`Class.forName`的方式获取`Class`对象，再获取`Method`对象，最后通过`Method.getGenericParameterTypes()`获取正确的`Type`对象，这个步骤是构造方法的参数类型和参数值。但是通过这个方式构造出来的参数类型和参数值，无法通过`proxy`对象来进行`method.invoke`，其原因就是原始接口的方法参数定义和代理对象的方法参数定义不同导致。这让我们如何是好。

继续往下看。

## Dubbo泛化调用

通过`Dubbo`的官网文档找到`Dubbo`支持`GenericService`泛化调用，什么是泛化调用？

泛化接口调用方式主要用于客户端没有 `API` 接口及模型类元的情况，参数及返回值中的所有 `POJO` 均用 `Map` 表示，通常用于框架集成，比如：实现一个通用的服务测试框架，可通过 `GenericService` 调用所有服务实现。

<span style="color:blue">ps. `GenericService`实际上是`Dubbo`提供的通用接口，解决使用通用接口调用任何服务方法</span>

这样我们就可以使用前面说到的参数反序列化方式来获取方法的参数类型和参数值，传入`GenericService`通用接口来对目标方法进行调用。

首先先让我们看一下`Dubbo`的泛化调用如何使用。

```
import com.alibaba.dubbo.rpc.config.ApplicationConfig;
import com.alibaba.dubbo.rpc.config.RegistryConfig;
import com.alibaba.dubbo.rpc.config.ConsumerConfig;
import com.alibaba.dubbo.rpc.config.ReferenceConfig;

Class clazz = Class.forName("com.package.JavaBean");
String method = "testMethod"
// 当前应用配置
ApplicationConfig application = new ApplicationConfig();
application.setName("yyy");
// 连接注册中心配置
RegistryConfig registry = new RegistryConfig();
registry.setAddress("10.20.130.230:9090");
// 注意：ReferenceConfig为重对象，内部封装了与注册中心的连接，以及与服务提供方的连接
// 引用远程服务
ReferenceConfig reference = new ReferenceConfig(); // 此实例很重，封装了与注册中心的连接以及与提供者的连接，请自行缓存，否则可能造成内存和连接泄漏
reference.setApplication(application);
reference.setRegistry(registry); // 多个注册中心可以用setRegistries()
reference.setInterface(clazz);
reference.setVersion("1.0.0");
reference.setRetries(0);
reference.setCluster("failfast");
reference.setTimeout(12001);
reference.setGeneric(true);
GenericService genericService = (GenericService) reference.get();
Object result = genericService.$invoke(method, parameterTypes, parameterValues);
```

只要给`reference`设置`generic`为`true`就可以使用`GenericService`通用接口来进行方法调用。

这样我们就可以顺利的完成任何参数类型方法的反射调用。

<span style="color:blue">从而避免了通过`Proxy`代理类获取到不正确的参数`Type`导致反序列化参数失败，这个原因前面也说了是因为原始接口的方法参数定义和代理对象的方法参数定义不同导致。</span>

接下来让我们看一下具体的实现

```
@SuppressWarnings({"unchecked", "rawtypes", "static-access"})
private Object callDubbo(SampleResult res) {
    ApplicationConfig application = new ApplicationConfig();
    application.setName("DubboSample");
    
    // 此实例很重，封装了与注册中心的连接以及与提供者的连接，请自行缓存，否则可能造成内存和连接泄漏
    ReferenceConfig reference = new ReferenceConfig();
    // 引用远程服务
    reference.setApplication(application);
    RegistryConfig registry = null;
    
    String protocol = getProtocol();
    if ("zookeeper".equals(protocol)) {
        // 连接注册中心配置
        registry = new RegistryConfig();
        registry.setProtocol("zookeeper");
        registry.setAddress(getAddress());
        reference.setRegistry(registry); // 多个注册中心可以用setRegistries()
    } else {
        StringBuffer sb = new StringBuffer();
        sb.append(protocol).append("://").append(getAddress()).append("/").append(getInterface());
        log.info("rpc invoker url : " + sb.toString());
        reference.setUrl(sb.toString());
    }
    try {
        Class clazz = Class.forName(getInterface());
        reference.setInterface(clazz);
        reference.setRetries(Integer.valueOf(getRetries()));
        reference.setCluster(getCluster());
        reference.setVersion(getVersion());
        reference.setTimeout(Integer.valueOf(getTimeout()));
        reference.setGeneric(true);
        GenericService genericService = (GenericService) reference.get();
        Method method = null;
        String[] parameterTypes = null;
        Object[] parameterValues = null;
        List<MethodArgument> args = getMethodArgs();
        List<String> paramterTypeList = null;
        List<Object> parameterValuesList = null;
        Method[] methods = clazz.getMethods();
		for (int i = 0; i < methods.length; i++) {
			Method m = methods[i];
			Type[] paramTypes = m.getGenericParameterTypes();
			paramterTypeList = new ArrayList<String>();
			parameterValuesList = new ArrayList<Object>();
			log.info("paramTypes.length="+paramTypes.length+"|args.size()="+args.size());
			if (m.getName().equals(getMethod()) && paramTypes.length == args.size()) {
				//名称与参数数量匹配，进行参数类型转换
				for (int j = 0; j < paramTypes.length; j++) {
					paramterTypeList.add(args.get(j).getParamType());
					ClassUtils.parseParameter(paramTypes[j], parameterValuesList, args.get(j));
				}
				if (parameterValuesList.size() == paramTypes.length) {
					//没有转换错误，数量应该一致
					method = m;
					break;
				}
			}
		}
        if (method == null) {
            res.setSuccessful(false);
            return "Method["+getMethod()+"] Not found!";
        }
        //发起调用
        parameterTypes = paramterTypeList.toArray(new String[paramterTypeList.size()]);
        parameterValues = parameterValuesList.toArray(new Object[parameterValuesList.size()]);
        Object result = null;
		try {
			result = genericService.$invoke(getMethod(), parameterTypes, parameterValues);
			res.setSuccessful(true);
		} catch (Throwable e) {
			log.error("接口返回异常：", e);
			res.setSuccessful(false);
			result = e;
		}
        return result;
    } catch (Exception e) {
        log.error("调用dubbo接口出错：", e);
        res.setSuccessful(false);
        return e;
    } finally {
        if (registry != null) {
            registry.destroyAll();
        }
        reference.destroy();
    }
}

## ClassUtils.parseParameter方法代码

public static void parseParameter(Type type,
		List<Object> parameterValuesList, MethodArgument arg)
		throws ClassNotFoundException {
	String className = getClassName(type);
	if (className.equals("int")) {
		parameterValuesList.add(Integer.parseInt(arg.getParamValue()));
	} else if (className.equals("double")) {
		parameterValuesList.add(Double.parseDouble(arg.getParamValue()));
	} else if (className.equals("short")) {
		parameterValuesList.add(Short.parseShort(arg.getParamValue()));
	} else if (className.equals("float")) {
		parameterValuesList.add(Float.parseFloat(arg.getParamValue()));
	} else if (className.equals("long")) {
		parameterValuesList.add(Long.parseLong(arg.getParamValue()));
	} else if (className.equals("byte")) {
		parameterValuesList.add(Byte.parseByte(arg.getParamValue()));
	} else if (className.equals("boolean")) {
		parameterValuesList.add(Boolean.parseBoolean(arg.getParamValue()));
	} else if (className.equals("char")) {
		parameterValuesList.add(arg.getParamValue().charAt(0));
	} else if (className.equals("java.lang.String")
			|| className.equals("String") || className.equals("string")) {
		parameterValuesList.add(String.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Integer")
			|| className.equals("Integer") || className.equals("integer")) {
		parameterValuesList.add(Integer.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Double")
			|| className.equals("Double")) {
		parameterValuesList.add(Double.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Short")
			|| className.equals("Short")) {
		parameterValuesList.add(Short.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Long")
			|| className.equals("Long")) {
		parameterValuesList.add(Long.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Float")
			|| className.equals("Float")) {
		parameterValuesList.add(Float.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Byte")
			|| className.equals("Byte")) {
		parameterValuesList.add(Byte.valueOf(arg.getParamValue()));
	} else if (className.equals("java.lang.Boolean")
			|| className.equals("Boolean")) {
		parameterValuesList.add(Boolean.valueOf(arg.getParamValue()));
	} else {
		parameterValuesList.add(JsonUtils.formJson(arg.getParamValue(),
				type));
	}
}

## JsonUtils.formJson方法代码

public static <T> T formJson(String json, Type type) {
	try {
		return gson.fromJson(json, type);
	} catch (JsonSyntaxException e) {
		logger.error("json to class[" + type.getClass().getName()
				+ "] is error!", e);
	}
	return null;
}
```

## 总结

1. 复杂参数类型：`Map<Object, ResourceVo>`、`List<ResourceVo>`、`List<Map<Object,ResourceVo>>`使用`gson.fromJson(json, classOfT)`反序列化会丢失内部的类型。通过使用`gson.fromJson(json, type)`方式可以得到正确的类型。
2. 通过`Proxy`对象的`method.getGenericParameterTypes()`获取的`Type`值全部为`java.lang.Class`，我们需要的是`java.util.Map<com.package.ResourceVo>`。
3. 使用`Class.forName`得到`Class`，再获取Method，再通过`method.getGenericParameterTypes()`获取我们想要的参数`Type`是：`java.util.Map<com.package.ResourceVo>`
4. 通过`Class.forName`得到`Class`，再获取Method，再通过`method.getGenericParameterTypes()`构造出来的参数类型和参数值，无法通过`Proxy`代理对象来进行`method.invoke`，其原因是：原始接口的方法参数定义和代理对象的方法参数定义不同导致。
4. 放弃通过`Proxy`对象的`method.invoke`方式调用接口，通过`Dubbo`的通用服务接口（`GenericService`）来调用任何服务接口方法：`GenericService.$invoke(method, parameterTypes, args)`

参数对照参考表如下

|Java类型|paramType|paramValue|
|:------|:--------|:---------|
|int|int|1|
|double|double|1.2|
|short|short|1|
|float|float|1.2|
|long|long|1|
|byte|byte|字节|
|boolean|boolean|true或false|
|char|char|A，如果字符过长取值为："STR".charAt(0)|
|java.lang.String|java.lang.String或String或string|字符串|
|java.lang.Integer|java.lang.Integer或Integer或integer|1|
|java.lang.Double|java.lang.Double或Double|1.2|
|java.lang.Short|java.lang.Short或Short|1|
|java.lang.Long|java.lang.Long或Long|1|
|java.lang.Float|java.lang.Float或Float|1.2|
|java.lang.Byte|java.lang.Byte或Byte|字节|
|java.lang.Boolean|java.lang.Boolean或Boolean|true或false|
|JavaBean|com.package.Bean|{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}|
|java.util.Map以及子类|java.util.Map以及子类|{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}|
|java.util.Map&#60;String,JavaBean> |java.util.Map|{"name":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}}|
|java.util.HashMap&#60;Object,Object>|java.util.HashMap|{"name":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}}|
|java.util.Collection以及子类|java.util.Collection以及子类|["a","b"]|
|java.util.List&#60;String>|java.util.List|["a","b"]|
|java.util.List&#60;JavaBean>|java.util.List|[{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}]|
|java.util.List&#60;Map&#60;Object, JavaBean>>|java.util.List|[{"name":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}},{"name":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001},"value":{"service":"test1","url":"test","action":"GET","enabled":true,"isPublic":false,"appId":8,"menuId":30001}}]|
|java.util.List&#60;Long>|java.util.List| [1,2,3]|
|java.util.ArrayList&#60;Object>|java.util.ArrayList|["ny",1,true]|