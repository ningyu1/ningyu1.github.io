---
toc : true
title : "Java中内部类使用注意事项，内部类对序列化与反序列化的影响"
description : "Java中内部类使用注意事项，内部类对序列化与反序列化的影响"
tags : [
	"inner class",
	"static",
	"non-static",
	"innerClassSerialization",
	"fastjson",
	"gson",
	"dubbo json"
]
date : "2018-03-06 16:50:17"
categories : [
	"java"
]
menu : "main"
---


现在很多服务架构都是微服务、分布式架构，开发模式也都是模块化开发，在分布式的开发方式下服务之间的调用不管是`RPC`还是`RESTful`或是其他`SOA`方案，均离不开序列化与反序列化，尤其是使用`Java`开发，`Bean`实现序列化接口几乎已经是必备的要求，而且这个要求已经纳入到很多大厂公司的开发规范中，开发规范中强制要求实现序列化接口和重写`toString`、`hashCode`方法。

前面提到了序列化与反序列化，那序列化与反序列化的对象就是开发人员写的`java bean`，不同的`java bean`会给序列化反序列化带来什么问题呢？接下来就让我们看一下内部类对序列化反序列化的影响。

在这之前我们先看一下常用的序列化工具：

* JavaSerialize 
* fastjson
* dubbo json
* google gson
* google protoBuf
* hessian
* kryo
* Avro
* fast-serialization
* jboss-serialization
* jboss-marshalling-river
* protostuff
* msgpack-databind
* json/jackson/databind 
* json/jackson/db-afterburner
* xml/xstream+c
* xml/jackson/databind-aalto

工具太多了这里就不列了，让我们先做一个测试。

# 测试

# 常规java bean

测试类：

```
import java.io.Serializable;

public class Test implements Serializable {
	private static final long serialVersionUID = 2010307013874058143L;
	private String name;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}
}
```

调用序列化与反序列化:

```
public static String toJson(Object obj) {
    try {
        return JSON.json(obj);
    } catch (IOException e) {
        log.error("class to json is error!", e);
    }
    return null;
}
public static <T> T formJson(String json, Class<T> classOfT) {
    try {
        return JSON.parse(json, classOfT);
    } catch (ParseException e) {
        log.error("json to class is error! "+classOfT.getName(), e);
    }
    return null;
}
public static void main(String[] args) {
	Test test = new Test();
	System.out.println(toJson(test));
	String json = "{\"name\":\"test\"}";
	test = formJson(json, Test.class);
	System.out.println(test.getName());
}
```

输出：

```
{"name":null}
test
```

我们能看到不管是序列化还是反序列化都没有任何问题，我们这里测试使用了常用的`fastjson`、`dubbo json`做了测试。

## 有内部类的java bean

测试类：

```
import java.io.Serializable;

public class Test implements Serializable {
	private static final long serialVersionUID = 2010307013874058143L;
	private String name;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public C1 c1;
	public C1 getC1() {
		return c1;
	}
	public void setC1(C1 c1) {
		this.c1 = c1;
	}
	public class C1 {
		public String name;
		public C1() {
		}
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
	}
}
```

调用序列化与反序列化:

```
public static String toJson(Object obj) {
    try {
        return JSON.json(obj);
    } catch (IOException e) {
        log.error("class to json is error!", e);
    }
    return null;
}
public static <T> T formJson(String json, Class<T> classOfT) {
    try {
        return JSON.parse(json, classOfT);
    } catch (ParseException e) {
        log.error("json to class is error! "+classOfT.getName(), e);
    }
    return null;
}
public static void main(String[] args) {
	Test test = new Test();
	System.out.println(toJson(test));
	String json = "{\"name\":\"test\",\"c1\":{\"name\":\"c1\"}}";
	test = formJson(json, Test.class);
	System.out.println(test.getC1().getName());
}
```


输出：

```
{"c1":null,"name":null,"C1":null}
Exception in thread "main" java.lang.NullPointerException
ERROR   2018-03-06 15:19:05.418 [xxx] (): json to class is error! Test
com.alibaba.dubbo.common.json.ParseException: java.lang.InstantiationException: Test$C1
java.lang.InstantiationException: Test$C1
	at java.lang.Class.newInstance(Class.java:359)
	at com.alibaba.dubbo.common.json.J2oVisitor.objectBegin(J2oVisitor.java:119)
	at com.alibaba.dubbo.common.json.JSON.parse(JSON.java:745)
	at com.alibaba.dubbo.common.json.JSON.parse(JSON.java:227)
	at com.alibaba.dubbo.common.json.JSON.parse(JSON.java:210)
```

可以成功序列化，但是反序列化报错了：无法创建实例`Test$C1`，这是什么问题？为什么会有这个错误？接下来我们分析一下

# 错误分析（java.lang.InstantiationException: Test$C1）

通过使用fastjson和dubbo json的错误代码跟踪，找到了`J2oVisitor.objectBegin(J2oVisitor.java:119)`这个地方，代码如下：

```
//下面是com.alibaba.dubbo.common.json.J2oVisitor的方法
public void objectBegin() throws ParseException
{
	mStack.push(mValue);
	mStack.push(mType);
	mStack.push(mWrapper);

	if( mType == Object.class || Map.class.isAssignableFrom(mType) )
	{
		if (! mType.isInterface() && mType != Object.class) {
			try {
				mValue = mType.newInstance();
			} catch (Exception e) {
				throw new IllegalStateException(e.getMessage(), e);
			}
		} else if (mType == ConcurrentMap.class) {
			mValue = new ConcurrentHashMap<String, Object>();
		} else {
			mValue = new HashMap<String, Object>();
		}
		mWrapper = null;
	} else {
		try {
			mValue = mType.newInstance();
			mWrapper = Wrapper.getWrapper(mType);
		} catch(IllegalAccessException e){ 
			throw new ParseException(StringUtils.toString(e)); 
		} catch(InstantiationException e){ 
			throw new ParseException(StringUtils.toString(e)); 
		}
	}
}
//下面是Class的方法
public T newInstance()
        throws InstantiationException, IllegalAccessException
{
    if (System.getSecurityManager() != null) {
        checkMemberAccess(Member.PUBLIC, Reflection.getCallerClass(), false);
    }

    // NOTE: the following code may not be strictly correct under
    // the current Java memory model.

    // Constructor lookup
    if (cachedConstructor == null) {
        if (this == Class.class) {
            throw new IllegalAccessException(
                "Can not call newInstance() on the Class for java.lang.Class"
            );
        }
        try {
            Class<?>[] empty = {};
            final Constructor<T> c = getConstructor0(empty, Member.DECLARED);
            // Disable accessibility checks on the constructor
            // since we have to do the security check here anyway
            // (the stack depth is wrong for the Constructor's
            // security check to work)
            java.security.AccessController.doPrivileged(
                new java.security.PrivilegedAction<Void>() {
                    public Void run() {
                            c.setAccessible(true);
                            return null;
                        }
                    });
            cachedConstructor = c;
        } catch (NoSuchMethodException e) {
            throw new InstantiationException(getName());
        }
    }
    Constructor<T> tmpConstructor = cachedConstructor;
    // Security check (same as in java.lang.reflect.Constructor)
    int modifiers = tmpConstructor.getModifiers();
    if (!Reflection.quickCheckMemberAccess(this, modifiers)) {
        Class<?> caller = Reflection.getCallerClass();
        if (newInstanceCallerCache != caller) {
            Reflection.ensureMemberAccess(caller, this, null, modifiers);
            newInstanceCallerCache = caller;
        }
    }
    // Run constructor
    try {
        return tmpConstructor.newInstance((Object[])null);
    } catch (InvocationTargetException e) {
        Unsafe.getUnsafe().throwException(e.getTargetException());
        // Not reached
        return null;
    }
}
```

代码中使用的是`tmpConstructor.newInstance((Object[])null)`不带参数的构造器，查看我们的原类，我们的内部类也是无参数的构造器，那为什么无法实例化呢？

我们来看一下我们的java源代码中内部类生成的class字节码文件，通过反编译工具查看如下：

```
public class Test$C1
{
  public String name;
  
  public Test$C1(Test paramTest) {}
  
  public String getName()
  {
    return this.name;
  }
  
  public void setName(String name)
  {
    this.name = name;
  }
}

```

我们是空构造器为什么生成的确是带参数的构造器而且参数`paramTest`的类型是`Test`，这是为什么呢？

我们来看一下JDK doc关于`Constructor.newInstance`它的解释

```
Uses the constructor represented by this Constructor object to create and initialize a new instance of the constructor's declaring class, with the specified initialization parameters. Individual parameters are automatically unwrapped to match primitive formal parameters, and both primitive and reference parameters are subject to method invocation conversions as necessary. 
If the number of formal parameters required by the underlying constructor is 0, the supplied initargs array may be of length 0 or null. 

If the constructor's declaring class is an inner class in a non-static context, the first argument to the constructor needs to be the enclosing instance; see The Java Language Specification, section 15.9.3. 

If the required access and argument checks succeed and the instantiation will proceed, the constructor's declaring class is initialized if it has not already been initialized. 

If the constructor completes normally, returns the newly created and initialized instance.

```

<span style="color:blue">*具体关注这句：If the constructor's declaring class is an inner class in a non-static context, the first argument to the constructor needs to be the enclosing instance; see The Java Language Specification, section 15.9.3*</span>

意思是说：如果构造函数的声明类是一个非静态（non-static）上下文中的内部类，则构造函数的第一个参数需要是封闭实例;参见Java语言规范，第15.9.3节。

[15.9.3节](https://docs.oracle.com/javase/specs/jls/se7/html/jls-15.html)具体看：15.9.3. Choosing the Constructor and its Arguments的说明

到这里我们应该清楚内部类在没有修饰符`static`和有修饰符`static`的区别了吧，就是`non-static`的内部类在生成的时候构造器第一个参数是`parent`实例，用来共享`parent`的属性访问的，那让我们将内部类修改为`static`再做一次测试验证。

# 验证

测试类：

```
import java.io.Serializable;

public class Test implements Serializable {
	private static final long serialVersionUID = 2010307013874058143L;
	private String name;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public C1 c1;
	public C1 getC1() {
		return c1;
	}
	public void setC1(C1 c1) {
		this.c1 = c1;
	}
	public static class C1 {
		public String name;
		public C1() {
		}
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
	}
}
```

<span style="color:blue">*ps.内部类C1增加了static修饰符*</span>

调用序列化与反序列化:

```
public static String toJson(Object obj) {
    try {
        return JSON.json(obj);
    } catch (IOException e) {
        log.error("class to json is error!", e);
    }
    return null;
}
public static <T> T formJson(String json, Class<T> classOfT) {
    try {
        return JSON.parse(json, classOfT);
    } catch (ParseException e) {
        log.error("json to class is error! "+classOfT.getName(), e);
    }
    return null;
}
public static void main(String[] args) {
	Test test = new Test();
	System.out.println(toJson(test));
	String json = "{\"name\":\"test\",\"c1\":{\"name\":\"c1\"}}";
	test = formJson(json, Test.class);
	System.out.println(test.getC1().getName());
}
```

输出：

```
{"c1":null,"name":null,"C1":null}
c1
```

结果可以正常的序列化了，以上测试使用的是`fastjson`与`dubbo json`进行测试。

# 总结

按照规范内部类是不太推荐使用的，如果要用尽量使用`static`修饰符修饰内部类，这个问题其实就是`Java`的基本功，尽量一个`Java`文件中只保留一个类，这样在大多数序列化与反序列化工具中都不会出现问题，也比较符合当下模块化开发的规范，内部类改为`static`修饰符修饰还可以有效的避免内存泄漏，很多大厂的性能建议文档与`Java`开发规范文档都可以看到对内部类使用的注意事项，有空多看看大厂的经验总结。

使用`Google`的`gson`进行测试，`non-static`的内部类可以正常序列化，`Google`出的工具包就是强大兼容了各种使用方式，从`gson`的`api`还发现可以通过参数来`disable`或`enable`对`inner class`序列化的支持，具体查看如下代码：

测试类：

```
import java.io.Serializable;

public class Test implements Serializable {
	private static final long serialVersionUID = 2010307013874058143L;
	private String name;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public C1 c1;
	public C1 getC1() {
		return c1;
	}
	public void setC1(C1 c1) {
		this.c1 = c1;
	}
	public class C1 {
		public String name;
		public C1() {
		}
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
	}
}
```

<span style="color:blue">*ps.注意我这里的内部类C1是non-static的*</span>

## gson开启内部类序列化

```
public static void main(String[] args) {
	Gson gson = new GsonBuilder().serializeNulls().create();
	Test test = new Test();
	test.setName("序列化参数name");
	System.out.println(gson.toJson(test));
	String json = "{\"name\":\"test\",\"c1\":{\"name\":\"c1\"}}";
	test = gson.fromJson(json, Test.class);
	System.out.println(test.getC1() == null ? "null" : test.getC1().getName());
}
```

<span style="color:blue">*ps.默认InnerClassSerialization就是开启的*</span>

输出：

```
{"name":"序列化参数name","c1":null}
c1
```

## gson禁用内部类序列化

```
public static void main(String[] args) {
	Gson gson = new GsonBuilder().serializeNulls().disableInnerClassSerialization().create();
	Test test = new Test();
	test.setName("序列化参数name");
	System.out.println(gson.toJson(test));
	String json = "{\"name\":\"test\",\"c1\":{\"name\":\"c1\"}}";
	test = gson.fromJson(json, Test.class);
	System.out.println(test.getC1() == null ? "null" : test.getC1().getName());
}
```

<span style="color:blue">*ps.调用GsonBuilder.disableInnerClassSerialization()禁用InnerClassSerialization*</span>

输出：

```
{"name":"序列化参数name"}
null
```

从而能看出`Google`出的工具包就是强大兼容各种使用方式，`Google`出的都是精品，从`guava`就可以看出。

好了到这里整个文章就介绍完了，最后还是一句老话：世界和平、Keep Real！