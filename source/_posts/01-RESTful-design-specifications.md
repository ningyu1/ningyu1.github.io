---
toc : true
title : "RESTful设计规范"
description : "RESTful设计规范"
tags : [
    "RESTful"
]
date : "2017-02-21 11:58:19"
categories : [
    "RESTful"
]
menu : "main"
---

# 一、 摘要（Abstract）

RESTful API 已经非常成熟，也得到了大家的认可。我们按照 [Richardson Maturity Model](https://martinfowler.com/articles/richardsonMaturityModel.html "Richardson Maturity Model") 对 REST 评价的模型，规范基于 level2 来设计

# 二、版本（Versioning）

API的版本号放入URL。例如：
```
https://api.jiuyescm.com/v1/
https://api.jiuyescm.com/v1.2/
```

# 三、资源、路径（Endpoint）

路径，API的具体地址。在REST中，每个地址都代表一个具体的资源（`Resource`）约定如下：

- 路径仅表示资源的路径（位置），尽量不要有actions操作（一些特殊的`actions`操作除外）
- 路径以 复数（名词） 进行命名资源，不管返回单个或者多个资源。
- 使用 小写字母、数字以及下划线（“_”） 。（下划线是为了区分多个单词，如user_name）
- 资源的路径从父到子依次如：

	```
	/{resource}/{resource_id}/{sub_resource}/{sub_resource_id}/{sub_resource_property}
	```
- 使用 `?` 来进行资源的过滤、搜索以及分页等
- 使用版本号，且版本号在资源路径之前
- 优先使用内容协商来区分表述格式，而不是使用后缀来区分表述格式
- 应该放在一个专用的域名下，如：`http：//api.jiuyescm.com`
- 使用SSL

综上，一个API路径可能会是
```
https://api.domain.com/v1/{resource}/{resource_id}/{sub_resource}/{sub_resource_id}/{sub_resource_property}
https://api.domain.com /v1/{resource}?page=1&page_size=10
https://api.domain.com /v1/{resource}?name=xx&sortby=name&order=asc
```

# 四、操作（HTTP Actions）

用`HTTP`动词（方法）表示对资源的具体操作。常用的`HTTP`动词有：
```
GET（SELECT）：从服务器取出资源（一项或多项）
POST（CREATE）：在服务器新建一个资源
PUT（UPDATE）：在服务器更新资源（客户端提供改变后的完整资源）  
PATCH（UPDATE）：在服务器更新资源（客户端提供改变的属性） 
DELETE（DELETE）：从服务器删除资源
还有两个不常用的HTTP动词
HEAD：获取资源的元数据
OPTIONS：获取信息，关于资源的哪些属性是客户端可以改变的
```

下面是一些例子

```
GET /users：列出所有用户  
POST /users：新建一个用户  
GET /users/{user_id}：获取某个指定用户的信息  
PUT /users/{user_id}：更新某个指定用户的信息（提供该用户的全部信息）  
PATCH /users/{user_id}：更新某个指定用户的信息（提供该用户的部分信息）  
DELETE /users/{user_id}：删除某个用户  
GET /users/{user_id}/resources：列出某个指定用户的所有权限资源  
DELETE /users/{user_id}/resources/{resources_id}：删除某个指定用户的指定权限资源
```

# 五、数据（Data Format）

数据是对资源的具体描述，分为请求数据和返回数据。约定如下：

- 查询，过滤条件使用query string，例如user?name=xxx
- Content body 仅仅用来传输数据
- 通过Content-Type指定请求与返回的数据格式。其中请求数据还要指定Accept。（我们暂时只使用Json）
- 数据应该拿来就能用，不应该还要进行转换操作
- 使用字符串（YYYY-MM-dd hh:mm:ss）格式表达时间字段，例如: 2017-02-20 16:00:00
- 数据采用UTF-8编码
- 返回的数据应该尽量简单，响应状态应该包含在响应头中
- 使用 小写字母、数字以及下划线（“_”） 描述字段，不使用大写描述字段（这个由于使用了一些开源的jar所以这个不强求，比如说pageinfo我们无法修改属性名称）
- 建议资源中的唯一标识命名为id（这个不强求，有的唯一标识名称确实比较复杂）
- 属性和字符串值必须使用双引号””（这个json转换默认规则）
- 建议对每个字段设置默认值（数组型可设置为[],字符串型可设置为””，数值可设置为0，对象可设置为{}）,这一条是为了方便前端/客户端进行判断字段存不存在操作（这样json转换会自动转成相应的字符）
- POST操作应该返回新建的资源；PUT/PATCH操作返回更新后的完整的资源；DELETE返回一个空文档；GET返回资源数组或当个资源
- 为了方便以后的扩展兼容，如果返回的是数组，强烈建议用一个包含如items属性的对象进行包裹，如：

```
{"items":[{},{}]}
```

示例：
```
POST https://api.domain.com/v1/users
Request
    headers:
        Accept: application/json
        Content-Type: application/json;charset=UTF-8
    body:
	 {
            "user_name": "ZhangSan",
            "address": "ujfhysdfsdf",
	         "nick": "ZS"
     }

Response
    status: 201 Created
    headers:
        Content-Type: application/json;charset=UTF-8
    body:
        {
           "requestId": sdfsdflkjoiusdf,
           "code": "",
	        "message": "",
	        "items":
		          {
		               "id":"111",
		               "user_name": "HingKwan",
		               "address": "ujfhysdfsdf",
	    	            "nick": "ZS"
		          }
        }

```

# 六、安全（Security）

## 调用限制

为了避免请求泛滥，给API设置速度限制很重要。入速度设置之后，可以在HTTP返回头上对返回的信息进行说明，下面是几个必须的返回头（依照twitter的命名规则）
```
X-Rate-Limit-Limit :当前时间段允许的并发请求数
X-Rate-Limit-Remaining:当前时间段保留的请求数
X-Rate-Limit-Reset:当前时间段剩余秒数
```
**这个我们一般会在getway中实现**

## 授权校验

RESTful API是无状态的也就是说用户请求的鉴权和cookie以及session无关，每一次请求都应该包含鉴权证明。
可以使用http请求头Authorization设置授权码; 必须使用User-Agent设置客户端信息, 无User-Agent请求头的请求应该被拒绝访问。具体的授权可以采用OAuth2，或者自己定义并实现相关的授权验证机制（基于token）。
**这个我们一般会在getway中实现**

## 错误

当API返回非2XX的HTTP响应时，应该采用统一的响应信息，格式如：
```
HTTP/1.1 400 Bad Request
Content-Type: application/json;charset=UTF-8
{
    "code":"INVALID_ARGUMENT",
    "message":"{error message}",
    "request_id":"sdfsdfo8lkjsdf",
    "items":[],
}
```
- HTTP Header Code：符合HTTP响应的状态码。详细见以下的“状态码”节
- code：用来表示某类错误不是具体错误，比如缺少参数等。是对HTTP Header Code的补充，开发团队可以根据自己的需要自己定义
- message：错误信息的摘要，应该是对用户处理错误有用的信息
- request_id：请求的id，方便开发定位发生错误的请求（可选）
- code的定义约定：
	- 采用 大写字母命名，字母与字母之间用下划线（”_”） 隔开
	- code应该用来定义错误类别，而非定义具体的某个错误。
	- 缺少参数使用：MISSING_X
	- 无效参数使用：INVALID_X
	- 逻辑验证错误使用：VALIDATION_X
	- 不存在使用：NO_FOUND_X

# 七、状态码（Status Codes）

服务器向用户返回的状态码和提示信息，常见的有以下一些（方括号中是该状态码对应的HTTP动词）。
```
200 OK - [GET/PUT/PATCH/DELETE]：服务器成功返回用户请求的数据，该操作是幂等的（Idempotent）。  
201 Created - [POST/PUT/PATCH]：用户新建或修改数据成功。  
202 Accepted - [*]：表示一个请求已经进入后台排队（异步任务）  
204 No Content - [DELETE]：用户删除数据成功。  
304 Not Modified   - HTTP缓存有效。
400 Invalid Request - [POST/PUT/PATCH]：用户发出的请求有错误，服务器没有进行新建或修改数据的操作，该操作是幂等的。  
401 Unauthorized - [*]：表示用户没有权限（令牌、用户名、密码错误）。  
403 Forbidden - [*] 表示用户得到授权（与401错误相对），但是访问是被禁止的。  
404 Not Found - [*]：用户发出的请求针对的是不存在的记录，服务器没有进行操作，该操作是幂等的。
405 Method Not Allowed - [*]：该http方法不被允许。  
406 Not Acceptable - [GET]：用户请求的格式不可得（比如用户请求JSON格式，但是只有XML格式）。  
410 Gone -[GET]：用户请求的资源被永久删除，且不会再得到的。  
415 Unsupported Media Type - [*]：请求类型错误。
422 Unprocesable Entity - [POST/PUT/PATCH] 当创建一个对象时，发生一个验证错误。  
429 Too Many Request - [*]：请求过多。
500 Internal Server Error - [*]：服务器发生错误，用户将无法判断发出的请求是否成功。  
503 Service Unavailable - [*]：服务当前无法处理请求。
```

# 八、异常规范（Exceptions）

- Controller中try catch住service的异常，再转换为restful中需要抛出的异常

```
try {
    Long id = userService.save(vo);
    vo.setId(id);
} catch(BizException e) {
    throw new UnprocesableEntityException(ErrorCode.USER_NAME_EXIST.getCode(), ErrorCode.USER_NAME_EXIST.getMessage());
}
```
- Controller中抛出的异常必须使用spring-mvc-rest包中的异常类，不允许自定义异常，选择需要返回的httpStatus对应的异常

```
#403 [*]：表示得到授权（与401错误相对），但是访问是被禁止的。
com.jiuyescm.spring.mvc.rest.exception.ForbiddenException

#401 [GET]：用户请求的资源被永久删除，且不会再得到的。
com.jiuyescm.spring.mvc.rest.exception.GoneException

#400 [POST/PUT/PATCH]：用户发出的请求有错误（常用在请求必要的参数错误上），服务器没有进行新建或修改数据的操作，该操作是幂等的。
com.jiuyescm.spring.mvc.rest.exception.InvalidRequestException

#406 [GET]：用户请求的格式不可得（比如用户请求JSON格式，但是只有XML格式）或（请求参数需要数字，用户传入字符串）
com.jiuyescm.spring.mvc.rest.exception.NotAcceptableException

#404 [*]：用户发出的请求针对的是不存在的记录，服务器没有进行操作，该操作是幂等的。
com.jiuyescm.spring.mvc.rest.exception.NotFoundException

#401 [*]：表示没有权限（令牌、用户名、密码错误，或任何资源没有权限）
com.jiuyescm.spring.mvc.rest.exception.UnauthorizedException

#422 [POST/PUT/PATCH] 当创建一个对象时，发生一个验证错误。
com.jiuyescm.spring.mvc.rest.exception.UnprocesableEntityException
```
- 抛出的异常中需要传入异常编码和异常信息，异常编码定义遵循上面 《安全中错误编码规范》

```
"MESSING_ID", "缺少参数：id"
"MESSING_NAME", "缺少参数：name"
"MESSING_ADDRESS", "缺少参数：address"
"USER_NAME_EXIST", "用户名已存在"
"USER_NOT_FOUND", "用户名不存在"
```
- 常用的错误编码、异常、httpStatus对应关系

```
"MESSING_ID", "缺少参数：id"、InvalidRequestException、400
"MESSING_NAME", "缺少参数：name"、InvalidRequestException、400
"MESSING_ADDRESS", "缺少参数：address"、InvalidRequestException、400
"USER_NAME_EXIST", "用户名已存在"、UnprocesableEntityException、422
"USER_NOT_FOUND", "用户名不存在"、NotFoundException、404
```

# 九、示例（Example）

采用user提供的示例代码

## POST /users

Resource
`POST /v1/users`

POST Parameters
Endpoint requires：

| Name | Type | Description |
| -----|:----:| -----------:|
|name|String|用户名称|
|address|String|用户住址|
and accepts a few other parameters listed below.

| Name | Type | Description |
| -----|:----:| -----------:|
|remark|String|描述信息|

Example
```
{
	"name":"tuyir",
	"address":"sdflkjsdf",
	"remark":"sdfoiu"
}
```

Response
Status-Code: 201 Created
```
{
  "code": "",
  "message": null,
  "items": {
    "id": 27,
    "name": "tuyir",
    "address": "sdflkjsdf",
    "remark": "sdfoiu"
  }
}
```
| Name | Type | Description |
| -----|:----:| -----------:|
|code	|String|	错误编码|
|message	|String|	错误描述|
|Items	|Objec|t	返回结果|
|id	|Long|	唯一标识|
|name	|String	|用户名称|
|address	|String|	家庭住址|
|remark|	String|	描述信息|

Error response
Status-Code: 400 Bad Request
```
{
  "code": "MESSING_NAME",
  "message": “缺少参数：name”,
  "items": {}
}
```
| Name | Type | Description |
| -----|:----:| -----------:|
|code|	String|	错误编码|
|message	|String	|错误描述|
|Items	|Object|	返回结果|

HTTP Error Codes

| HTTP Status  | Code | Description |
| -----|:----:| -----------:|
|400	|MESSING_NAME|	缺少参数：name|
|400	|MESSING_ADDRESS|	缺少参数：address|
|422	|USER_NAME_EXIST|	用户名已存在|
|500	|INTERNAL_SERVER_ERROR|	未知的错误|

## DELETE /users/{user_id}

Resource
`DELETE /v1/users/{user_id}`

Path Parameters

| Name | Type | Description |
| -----|:----:| -----------:|
|user_id|	Long|	用户唯一标识|

Query Parameters
None

Example Request
```
curl –H ‘Content-Type: application/json’\
-X DELETE \
‘https://api.jiuyescm.com/v1/users/111’ 
```

Response
Status-Code: 204 No Content

HTTP Error Codes

| HTTP Status  | Code | Description |
| -----|:----:| -----------:|
|400	|MESSING_ID	|缺少参数：id|
|404	|USER_NOT_FOUND	|用户不存在|

## PUT /users

Resource
`PUT /v1/users`

PUT Body Parameters
Endpoint requires：

| Name | Type | Description |
| -----|:----:| -----------:|
|user_id|	Long|	用户唯一标识|
|user_name|	String|	用户名称|
|address|	String|	用户住址|

and accepts a few other parameters listed below..

| Name | Type | Description |
| -----|:----:| -----------:|
|remark|	String|	描述信息|

Example
```
{
    "user_id": 12,
	"name":"tuyir",
	"address":"sdflkjsdf",
	"remark":"sdfoiu"
}
```

Response
Status-Code: 200 OK
```
{
  "code": "",
  "message": null,
  "items": {
    "id": 12,
    "name": "tuyir",
    "address": "sdflkjsdf",
    "remark": "sdfoiu"
  }
}
```
| Name | Type | Description |
| -----|:----:| -----------:|
|code	|String	|错误编码|
|message	|String	|错误描述|
|Items	|Object	|返回结果|
|id	|Long	|唯一标识|
|name	|String	|用户名称|
|address	|String	|家庭住址|
|remark	|String	|描述信息|

Error response
Status-Code: 400 Bad Request
```
{
  "code": "MESSING_NAME",
  "message": “缺少参数：name”,
  "items": {}
}
```

| Name | Type | Description |
| -----|:----:| -----------:|
|code	|String	|错误编码|
|message	|String	|错误描述|

HTTP Error Codes

| HTTP Status | Code | Description |
| -----|:----:| -----------:|
|code	|String	|错误编码|
|400	|MESSING_ID	|缺少参数：id|
|400	|MESSING_NAME	|缺少参数：name|
|400	|MESSING_ADDRESS	|缺少参数：address|
|422	|USER_NAME_EXIST	|用户名已存在|
|500	|INTERNAL_SERVER_ERROR	|未知的错误|

## GET /users/{user_id}

Resource
`GET /v1/users/{user_id}`

Path Parameters

| Name | Type | Description |
| -----|:----:| -----------:|
|user_id|	Long|	用户唯一标识|

Example Request
```
Curl –H 'Content-Type: application/json' \
'https://api.jiuyescm.com/v1/users/12'
```

Response
Status-Code: 200 OK
```
{
  "code": "",
  "message": null,
  "items": {
    "id": 12,
    "name": "tuyir",
    "address": "sdflkjsdf",
    "remark": "sdfoiu"
  }
}
```

| Name | Type | Description |
| -----|:----:| -----------:|
|code	|String	|错误编码|
|message	|String	|错误描述|
|Items	|Object|	返回结果|
|id	|String	|唯一标识|
|name	|String	|用户名称|
|address	|String	|家庭住址|
|remark	|String|	描述信息|

Error response
Status-Code: 404 Bad Request
```
{
  "code": " USER_NOT_FOUND",
  "message": “用户不存在”,
  "items": {}
}
```
| Name | Type | Description |
| -----|:----:| -----------:|
|code	|String	|错误编码|
|message|String	|错误描述|

HTTP Error Codes

| HTTP Status | Code | Description |
| -----|:----:| -----------:|
|400	|MESSING_ID	|缺少参数：id|
|404	|USER_NOT_FOUND	|用户不存在|

## GET /users

Resource
`GET /v1/users`

Query Parameters

| Name | Type | Description |
| -----|:----:| -----------:|
|name	|String	|根据用户名称进行查询|
|page	|int	|第几页，不传入默认1|
|page_size|	int	|每页返回多少条结果，不传入默认20|

Example Request
```
Curl –H 'Content-Type: application/json' \
'https://api.jiuyescm.com/v1/users?name=xxx&page=1&page_size=20'
```

Response
Status-Code: 200 Success
```
{
  "code": "",
  "message": "",
  "items": {
    "pageNum": 1,
    "pageSize": 20,
    "size": 17,
    "startRow": 1,
    "endRow": 17,
    "total": 17,
    "pages": 1,
    "list": [
      {
        "id": 2,
        "name": "ningyu1",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 3,
        "name": "ningyu2",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 4,
        "name": "ningyu3",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 5,
        "name": "ningyu4",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 6,
        "name": "ningyu5",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 7,
        "name": "8888",
        "address": "8888",
        "remark": "8888"
      },
      {
        "id": 8,
        "name": "444",
        "address": "444",
        "remark": "444"
      },
      {
        "id": 9,
        "name": "ningyu7",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 12,
        "name": "ningyu9",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 13,
        "name": "ningyu10",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 17,
        "name": "ningyu",
        "address": "sdflkjsdf",
        "remark": null
      },
      {
        "id": 20,
        "name": "9999",
        "address": "sdflkjsdf",
        "remark": null
      },
      {
        "id": 23,
        "name": "888",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 24,
        "name": "222",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 25,
        "name": "222444",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 26,
        "name": "222444sdf",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      },
      {
        "id": 27,
        "name": "tuyir",
        "address": "sdflkjsdf",
        "remark": "sdfoiu"
      }
    ],
    "firstPage": 1,
    "prePage": 0,
    "nextPage": 0,
    "lastPage": 1,
    "isFirstPage": true,
    "isLastPage": true,
    "hasPreviousPage": false,
    "hasNextPage": false,
    "navigatePages": 8,
    "navigatepageNums": [
      1
    ]
  }
}
```

| Name | Type | Description |
| -----|:----:| -----------:|
|code	|String	|错误编码|
|message	|String	|错误描述|
|Items	|Object	|返回结果|
|id	|Long	|唯一标识|
|name	|String	|用户名称|
|address	|String	|家庭住址|
|remark	|String	|描述信息|
