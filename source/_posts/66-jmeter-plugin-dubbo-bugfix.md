---
toc : true
title : "Bug Fix Version V1.1.0, Dubbo Plugin for Apache JMeter"
description : "Bug Fix Version V1.1.0, Dubbo Plugin for Apache JMeter"
tags : [
	"jmeter",
	"dubbo",
	"test",
	"Dubbo可视化测试工具",
	"Jmeter对Dubbo接口进行可视化压力测试",
	"Dubbo Jmeter插件"
]
date : "2018-03-07 18:00:54"
categories : [
    "test"
]
menu : "main"
---

首先先感谢网友 @流浪的云 提的bug，让我感觉到写这个工具没有白费还有点价值，非常感谢，

他在使用`jmeter-plugin-dubbo`插件时发现`GUI`中输入的信息无法使用`Jmeter`变量`${var}`与函数来进行参数化，以下是我修复这个问题的记录。

# 项目地址

jmeter-plugin-dubbo项目已经transfer到dubbo group下

[github: jmeter-plugin-dubbo](https://github.com/dubbo/jmeter-plugins-dubbo) 

[码云: jmeter-plugin-dubbo]( https://gitee.com/ningyu/jmeter-plugins-dubbo)

# 问题描述

1. `jmeter-plugin-dubbo`插件`GUI`输入的信息无法使用`${var}`变量来进行参数化

# 问题修复

`Jmeter`的输出要想使用用户自定义变量、`CSV`变量、`BeanShell`、函数来进行参数化，必须将输入的参数通过`JMeterProperty`的子类`add`到`Jmeter`管理。如果使用的是`Swing`的`Bean`绑定机制可以很好的支持变量与函数参数化，如果是手写的GUI与Sample就需要注意这一点，可能写出来的插件不能使用变量`${var}`参数化。

我之前在处理参数值在GUI和Sample之间传递时，没有使用`org.apache.jmeter.testelement.property.JMeterProperty `系列子类来处理参数，因此变量无法支持，让我们来看一下区别。

先让我们看一下`org.apache.jmeter.testelement.property.JMeterProperty`都有哪些子类。

![](/img/jmeter-plugins-dubbo/7.png)

我们之前使用的参数赋值是这样的：

```
public String getVersion() {
    return this.getPropertyAsString(FIELD_DUBBO_VERSION, DEFAULT_VERSION);
}
public void setVersion(String version) {
    this.setProperty(FIELD_DUBBO_VERSION, version);
}
```

这种方式是无法支持使用`${var}`变量来参数化赋值的（也就是动态赋值）。

我们应该给`setProperty`传入`JMeterProperty`的子类来支持变量参数化，如下：

```
public String getVersion() {
    return this.getPropertyAsString(FIELD_DUBBO_VERSION, DEFAULT_VERSION);
}
public void setVersion(String version) {
    this.setProperty(new StringProperty(FIELD_DUBBO_VERSION, version));
}
```

<span style="color:blue">*ps.注意setProperty的使用不一样，这里使用的是new StringProperty*</span>

上面的参数还相对简单的普通字符串参数，当我们遇到集合或更加复杂的参数类型时如何处理？

我本以为使用`JMeterProperty`的子类`CollectionProperty`是可以让集合参数支持变量参数化的，结果测试下来没有任何用，传入的`${var}`变量，在运行的时候还是变量没有变成相应的值。

于是又换成`MapProperty`和`ObjectProperty`一样无法支持变量参数化。

查看`Jmeter Plugins`的`Http Sample`源码，看他是如何处理的。

## org.apache.jmeter.protocol.http.util.HTTPArgument源码

```
package org.apache.jmeter.protocol.http.util;

import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.LinkedList;
import java.util.List;
import org.apache.jmeter.config.Argument;
import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.testelement.property.BooleanProperty;
import org.apache.jmeter.testelement.property.JMeterProperty;
import org.apache.jorphan.logging.LoggingManager;
import org.apache.log.Logger;

public class HTTPArgument
  extends Argument
  implements Serializable
{
  private static final Logger log = ;
  private static final long serialVersionUID = 240L;
  private static final String ALWAYS_ENCODE = "HTTPArgument.always_encode";
  private static final String USE_EQUALS = "HTTPArgument.use_equals";
  private static final EncoderCache cache = new EncoderCache(1000);
  
  public HTTPArgument(String name, String value, String metadata)
  {
    this(name, value, false);
    setMetaData(metadata);
  }
  
  public void setUseEquals(boolean ue)
  {
    if (ue) {
      setMetaData("=");
    } else {
      setMetaData("");
    }
    setProperty(new BooleanProperty("HTTPArgument.use_equals", ue));
  }
  
  public boolean isUseEquals()
  {
    boolean eq = getPropertyAsBoolean("HTTPArgument.use_equals");
    if ((getMetaData().equals("=")) || ((getValue() != null) && (getValue().length() > 0)))
    {
      setUseEquals(true);
      return true;
    }
    return eq;
  }
  
  public void setAlwaysEncoded(boolean ae)
  {
    setProperty(new BooleanProperty("HTTPArgument.always_encode", ae));
  }
  
  public boolean isAlwaysEncoded()
  {
    return getPropertyAsBoolean("HTTPArgument.always_encode");
  }
  
  public HTTPArgument(String name, String value)
  {
    this(name, value, false);
  }
  
  public HTTPArgument(String name, String value, boolean alreadyEncoded)
  {
    this(name, value, alreadyEncoded, "UTF-8");
  }
  
  public HTTPArgument(String name, String value, boolean alreadyEncoded, String contentEncoding)
  {
    setAlwaysEncoded(true);
    if (alreadyEncoded) {
      try
      {
        if (log.isDebugEnabled()) {
          log.debug("Decoding name, calling URLDecoder.decode with '" + name + "' and contentEncoding:" + "UTF-8");
        }
        name = URLDecoder.decode(name, "UTF-8");
        if (log.isDebugEnabled()) {
          log.debug("Decoding value, calling URLDecoder.decode with '" + value + "' and contentEncoding:" + contentEncoding);
        }
        value = URLDecoder.decode(value, contentEncoding);
      }
      catch (UnsupportedEncodingException e)
      {
        log.error(contentEncoding + " encoding not supported!");
        throw new Error(e.toString(), e);
      }
    }
    setName(name);
    setValue(value);
    setMetaData("=");
  }
  
  public HTTPArgument(String name, String value, String metaData, boolean alreadyEncoded)
  {
    this(name, value, metaData, alreadyEncoded, "UTF-8");
  }
  
  public HTTPArgument(String name, String value, String metaData, boolean alreadyEncoded, String contentEncoding)
  {
    this(name, value, alreadyEncoded, contentEncoding);
    setMetaData(metaData);
  }
  
  public HTTPArgument(Argument arg)
  {
    this(arg.getName(), arg.getValue(), arg.getMetaData());
  }
  
  public HTTPArgument() {}
  
  public void setName(String newName)
  {
    if ((newName == null) || (!newName.equals(getName()))) {
      super.setName(newName);
    }
  }
  
  public String getEncodedValue()
  {
    try
    {
      return getEncodedValue("UTF-8");
    }
    catch (UnsupportedEncodingException e)
    {
      throw new Error("Should not happen: " + e.toString());
    }
  }
  
  public String getEncodedValue(String contentEncoding)
    throws UnsupportedEncodingException
  {
    if (isAlwaysEncoded()) {
      return cache.getEncoded(getValue(), contentEncoding);
    }
    return getValue();
  }
  
  public String getEncodedName()
  {
    if (isAlwaysEncoded()) {
      return cache.getEncoded(getName());
    }
    return getName();
  }
  
  public static void convertArgumentsToHTTP(Arguments args)
  {
    List<Argument> newArguments = new LinkedList();
    for (JMeterProperty jMeterProperty : args.getArguments())
    {
      Argument arg = (Argument)jMeterProperty.getObjectValue();
      if (!(arg instanceof HTTPArgument)) {
        newArguments.add(new HTTPArgument(arg));
      } else {
        newArguments.add(arg);
      }
    }
    args.removeAllArguments();
    args.setArguments(newArguments);
  }
}
```

## org.apache.jmeter.protocol.http.gui.HTTPArgumentsPanel源码

```
package org.apache.jmeter.protocol.http.gui;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Iterator;
import javax.swing.JMenuItem;
import javax.swing.JPopupMenu;
import javax.swing.JTable;
import org.apache.commons.lang3.BooleanUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.jmeter.config.Argument;
import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.config.gui.ArgumentsPanel;
import org.apache.jmeter.protocol.http.util.HTTPArgument;
import org.apache.jmeter.testelement.TestElement;
import org.apache.jmeter.testelement.property.JMeterProperty;
import org.apache.jmeter.util.JMeterUtils;
import org.apache.jorphan.gui.GuiUtils;
import org.apache.jorphan.gui.ObjectTableModel;
import org.apache.jorphan.reflect.Functor;

public class HTTPArgumentsPanel
  extends ArgumentsPanel
{
  private static final long serialVersionUID = 240L;
  private static final String ENCODE_OR_NOT = "encode?";
  private static final String INCLUDE_EQUALS = "include_equals";
  
  protected void initializeTableModel()
  {
    this.tableModel = new ObjectTableModel(new String[] { "name", "value", "encode?", "include_equals" }, HTTPArgument.class, new Functor[] { new Functor("getName"), new Functor("getValue"), new Functor("isAlwaysEncoded"), new Functor("isUseEquals") }, new Functor[] { new Functor("setName"), new Functor("setValue"), new Functor("setAlwaysEncoded"), new Functor("setUseEquals") }, new Class[] { String.class, String.class, Boolean.class, Boolean.class });
  }
  
  public static boolean testFunctors()
  {
    HTTPArgumentsPanel instance = new HTTPArgumentsPanel();
    instance.initializeTableModel();
    return instance.tableModel.checkFunctors(null, instance.getClass());
  }
  
  protected void sizeColumns(JTable table)
  {
    GuiUtils.fixSize(table.getColumn("include_equals"), table);
    GuiUtils.fixSize(table.getColumn("encode?"), table);
  }
  
  protected HTTPArgument makeNewArgument()
  {
    HTTPArgument arg = new HTTPArgument("", "");
    arg.setAlwaysEncoded(false);
    arg.setUseEquals(true);
    return arg;
  }
  
  public HTTPArgumentsPanel()
  {
    super(JMeterUtils.getResString("paramtable"));
    init();
  }
  
  public TestElement createTestElement()
  {
    Arguments args = getUnclonedParameters();
    super.configureTestElement(args);
    return (TestElement)args.clone();
  }
  
  public Arguments getParameters()
  {
    Arguments args = getUnclonedParameters();
    return (Arguments)args.clone();
  }
  
  private Arguments getUnclonedParameters()
  {
    stopTableEditing();
    
    Iterator<HTTPArgument> modelData = this.tableModel.iterator();
    Arguments args = new Arguments();
    while (modelData.hasNext())
    {
      HTTPArgument arg = (HTTPArgument)modelData.next();
      args.addArgument(arg);
    }
    return args;
  }
  
  public void configure(TestElement el)
  {
    super.configure(el);
    if ((el instanceof Arguments))
    {
      this.tableModel.clearData();
      HTTPArgument.convertArgumentsToHTTP((Arguments)el);
      for (JMeterProperty jMeterProperty : ((Arguments)el).getArguments())
      {
        HTTPArgument arg = (HTTPArgument)jMeterProperty.getObjectValue();
        this.tableModel.addRow(arg);
      }
    }
    checkButtonsStatus();
  }
  
  protected boolean isMetaDataNormal(HTTPArgument arg)
  {
    return (arg.getMetaData() == null) || (arg.getMetaData().equals("=")) || ((arg.getValue() != null) && (arg.getValue().length() > 0));
  }
  
  protected Argument createArgumentFromClipboard(String[] clipboardCols)
  {
    HTTPArgument argument = makeNewArgument();
    argument.setName(clipboardCols[0]);
    if (clipboardCols.length > 1)
    {
      argument.setValue(clipboardCols[1]);
      if (clipboardCols.length > 2)
      {
        argument.setAlwaysEncoded(Boolean.parseBoolean(clipboardCols[2]));
        if (clipboardCols.length > 3)
        {
          Boolean useEqual = BooleanUtils.toBooleanObject(clipboardCols[3]);
          
          argument.setUseEquals(useEqual != null ? useEqual.booleanValue() : true);
        }
      }
    }
    return argument;
  }
  
  private void init()
  {
    JTable table = getTable();
    JPopupMenu popupMenu = new JPopupMenu();
    JMenuItem variabilizeItem = new JMenuItem(JMeterUtils.getResString("transform_into_variable"));
    variabilizeItem.addActionListener(new ActionListener()
    {
      public void actionPerformed(ActionEvent e)
      {
        HTTPArgumentsPanel.this.transformNameIntoVariable();
      }
    });
    popupMenu.add(variabilizeItem);
    table.setComponentPopupMenu(popupMenu);
  }
  
  private void transformNameIntoVariable()
  {
    int[] rowsSelected = getTable().getSelectedRows();
    for (int selectedRow : rowsSelected)
    {
      String name = (String)this.tableModel.getValueAt(selectedRow, 0);
      if (StringUtils.isNotBlank(name))
      {
        name = name.trim();
        name = name.replaceAll("\\$", "_");
        name = name.replaceAll("\\{", "_");
        name = name.replaceAll("\\}", "_");
        this.tableModel.setValueAt("${" + name + "}", selectedRow, 1);
      }
    }
  }
}
```

能发现它使用的是继承`Argument`来处理和`GUI`之间的参数传递，使用继承`ArgumentsPanel`来处理`GUI`页面，这个就是我们上面说的，通过`Swing`的`Bean`绑定机制来进行开发，很遗憾我们没有使用这种方式，如果要改成这种方式，整个代码结构都要修改，成本太大。

但是我们发现像`String`，`Integer`等这种普通类型的参数通过使用`JMeterProperty`的子类可以很好的支持变量参数化，那我们能不能将集合参数拉平来直接使用普通类型的参数来处理，我承认这种方式有点恶心。

# 解决方式

首先我们的集合参数有索引下标和总行数，每一行有两列，那就修改集合参数的赋值，代码如下：

```
//标记集合参数前缀
public static String FIELD_DUBBO_METHOD_ARGS = "FIELD_DUBBO_METHOD_ARGS";
//集合参数总数
public static String FIELD_DUBBO_METHOD_ARGS_SIZE = "FIELD_DUBBO_METHOD_ARGS_SIZE";

public List<MethodArgument> getMethodArgs() {
	int paramsSize = this.getPropertyAsInt(FIELD_DUBBO_METHOD_ARGS_SIZE, 0);
	List<MethodArgument> list = new ArrayList<MethodArgument>();
	for (int i = 1; i <= paramsSize; i++) {
		String paramType = this.getPropertyAsString(FIELD_DUBBO_METHOD_ARGS + "_PARAM_TYPE" + i);
		String paramValue = this.getPropertyAsString(FIELD_DUBBO_METHOD_ARGS + "_PARAM_VALUE" + i);
		MethodArgument args = new MethodArgument(paramType, paramValue);
		list.add(args);
	}
	return list;
}
public void setMethodArgs(List<MethodArgument> methodArgs) {
	int size = methodArgs == null ? 0 : methodArgs.size();
	this.setProperty(new IntegerProperty(FIELD_DUBBO_METHOD_ARGS_SIZE, size));
	if (size > 0) {
		for (int i = 1; i <= methodArgs.size(); i++) {
			this.setProperty(new StringProperty(FIELD_DUBBO_METHOD_ARGS + "_PARAM_TYPE" + i, methodArgs.get(i-1).getParamType()));
			this.setProperty(new StringProperty(FIELD_DUBBO_METHOD_ARGS + "_PARAM_VALUE" + i, methodArgs.get(i-1).getParamValue()));
		}
	}
}
```

上面的代码就是将集合参数拉平来进行传递，大致的结果如下：

```
FIELD_DUBBO_METHOD_ARGS_SIZE = 2
FIELD_DUBBO_METHOD_ARGS_SIZE_PARAM_TYPE_1 = xx${var1}xx 
FIELD_DUBBO_METHOD_ARGS_SIZE__PARAM_VALUE_1 = xx${var2}xx 
FIELD_DUBBO_METHOD_ARGS_SIZE_PARAM_TYPE_2 = xx${var3}xx 
FIELD_DUBBO_METHOD_ARGS_SIZE__PARAM_VALUE_2 = xx${var4}xx 
```

让我们测试一下是否可用。

![](/img/jmeter-plugins-dubbo/8.png)
![](/img/jmeter-plugins-dubbo/9.png)
![](/img/jmeter-plugins-dubbo/10.png)

测试结果`GUI`上所有的输入框均可以支持`Jmeter`变量`${var}`参数化.

我觉得应该还是更加完美的解决办法只不过我没有找到，有空了再细致研究一下`Jmeter`的插件开发的细节看看能否找到突破口。

再次感谢网友 @流浪的云 提的bug，非常感谢！感谢使用插件的朋友多提rp和bug，让我们来一起完善起来，感谢这个开放的世界，最后还是一句老话：世界和平，Keep Real!
