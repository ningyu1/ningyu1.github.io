---
toc : true
title : "Webpack 打包优化之速度篇"
description : "Webpack 打包优化之速度篇"
zhuan : true
tags : [
    "Webpack",
	"Vue",
	"React",
	"Angular"
]
date : "2017-09-20 11:57:36"
categories : [
    "Webpack",
	"Vue",
	"React",
	"Angular"
]
menu : "main"
---

文章来源：https://jeffjade.com/2017/08/12/125-webpack-package-optimization-for-speed/
作者：@晚晴幽草轩轩主

在前文 [Webpack 打包优化之体积](https://ningyu1.github.io/site/post/26-webpack1/)篇中，对如何减小 `Webpack` 打包体积，做了些探讨；当然，那些法子对于打包速度的提升，也是大有裨益。然而，打包速度之于**开发体验**和**及时构建**，相当重要；所以有必要对其做更为深入的研究，以便完善工作流，这就是本文存在的缘由。

![Webpack Package optimization](/img/webpack/1.png)

<center><em>Webpack Package optimization</em></center>

## 减小文件搜索范围

在使用实际项目开发中，为了提升开发效率，很明显你会使用很多成熟第三方库；即便自己写的代码，模块间相互引用，为了方便也会使用相对路劲，或者别名(`alias`)；这中间如果能使得 `Webpack` 更快寻找到目标，将对打包速度产生很是积极的影响。于此，我们需要做的即：减小文件搜索范围，从而提升速度；实现这一点，可以有如下两法：

### 配置 resolve.modules

`Webpack`的`resolve.modules`配置模块库（即 node_modules）所在的位置，在 js 里出现 `import 'vue'` 这样不是相对、也不是绝对路径的写法时，会去 `node_modules` 目录下找。但是默认的配置，会采用向上递归搜索的方式去寻找，但通常项目目录里只有一个 `node_modules`，且是在项目根目录，为了减少搜索范围，可以直接写明 `node_modules` 的全路径；同样，对于别名(`alias`)的配置，亦当如此：

```
function resolve (dir) {
  return path.join(__dirname, '..', dir)
}
module.exports = {
  resolve: {
    extensions: ['.js', '.vue', '.json'],
    modules: [
      resolve('src'),
      resolve('node_modules')
    ],
    alias: {
      'vue$': 'vue/dist/vue.common.js',
      'src': resolve('src'),
      'assets': resolve('src/assets'),
      'components': resolve('src/components'),
      // ...
      'store': resolve('src/store')
    }
  },
  ...
}
```

需要额外补充一点的是，这是 Webpack2.* 以上的写法。在 1.* 版本中，使用的是 `resolve.root`，如今已经被弃用为 `resolve.modules`；同时被弃用的还有`resolve.fallback`、`resolve.modulesDirectories`。

### 设置 test & include & exclude

`Webpack` 的装载机(loaders)，允许每个子项都可以有以下属性：

```
test：必须满足的条件（正则表达式，不要加引号，匹配要处理的文件）
exclude：不能满足的条件（排除不处理的目录）
include：导入的文件将由加载程序转换的路径或文件数组（把要处理的目录包括进来）
loader：一串“！”分隔的装载机（2.0版本以上，”-loader”不可以省略）
loaders：作为字符串的装载器阵列
```

对于`include`，更精确指定要处理的目录，这可以减少不必要的遍历，从而减少性能损失。同样，对于已经明确知道的，不需要处理的目录，则应该予以排除，从而进一步提升性能。假设你有一个第三方组件的引用，它肯定位于`node_modules`，通常它将有一个 `src` 和一个 `dist` 目录。如果配置 `Webpack` 来排除 `node_modules`，那么它将从 `dist` 已经编译的目录中获取文件。否则会再次编译它们。故而，合理的设置 `include` & `exclude`，将会极大地提升 `Webpack` 打包优化速度，比如像这样：

```
module: {
  preLoaders: [
    {
      test: /\.js$/,
      loader: 'eslint',
      include: [resolve('src')],
      exclude: /node_modules/
    },
    {
      test: /\.svg$/,
      loader: 'svgo?' + JSON.stringify(svgoConfig)，
      include: [resolve('src/assets/icons')],
      exclude: /node_modules/
    }
  ],
  loaders: [
    {
      test: /\.vue$/,
      loader: 'vue-loader',
      include: [resolve('src')],
      exclude: /node_modules\/(?!(autotrack|dom-utils))|vendor\.dll\.js/
    },
    {
      test: /\.(png|jpe?g|gif|svg)(\?.*)?$/,
      loader: 'url',
      exclude: /assets\/icons/,
      query: {
        limit: 10000,
        name: utils.assetsPath('img/[name].[hash:7].[ext]')
      }
    }
  ]
}
```

## 增强代码代码压缩工具

`Webpack` 默认提供的 `UglifyJS` 插件，由于采用单线程压缩，速度颇慢 ；推荐采用 `webpack-parallel-uglify-plugin` 插件，她可以并行运行 `UglifyJS` 插件，更加充分而合理的使用 `CPU` 资源，这可以大大减少的构建时间；当然，该插件应用于生产环境而非开发环境，其做法如下，

```
new webpack.optimize.UglifyJsPlugin({
  compress: {
    warnings: false
  },
  sourceMap: true
})
```

替换如上自带的 `UglifyJsPlugin` 写法为如下配置即可：

```
var ParallelUglifyPlugin = require('webpack-parallel-uglify-plugin');
new ParallelUglifyPlugin({
  cacheDir: '.cache/',
  uglifyJS:{
    output: {
      comments: false
    },
    compress: {
      warnings: false
    }
  }
})
```

当然也有其他同类型的插件，比如：[webpack-uglify-parallel](https://www.npmjs.com/package/webpack-uglify-parallel)，但根据自己实践效果来看，并没有 `webpack-parallel-uglify-plugin` 表现的那么卓越，有兴趣的朋友，可以更全面的做下对比，择优选用。需要额外说明的是，`webpack-parallel-uglify-plugin` 插件的运用，会相对 `UglifyJsPlugin` 打出的包，看起来略大那么一丢丢(其实可以忽略不计)；如果在你使用时也是如此，那么在打包速度跟包体积之间，你应该有自己的抉择。

## 用 Happypack 来加速代码构建

你知道，`Webpack` 中为了方便各种资源和类型的加载，设计了以 `loader` 加载器的形式读取资源，但是受限于 `nodejs` 的编程模型影响，所有的 `loader` 虽然以 `async` 的形式来并发调用，但是还是运行在单个 `node` 的进程，以及在同一个事件循环中，这就直接导致了些问题：当同时读取多个`loader`文件资源时，比如`babel-loader`需要 `transform` 各种`jsx`，`es6`的资源文件。在这种同步计算同时需要大量耗费 `cpu` 运算的过程中，`node`的单进程模型就无优势了，而 `Happypack` 就是针对解决此类问题而生的存在。

![Webpack-Happypack](/img/webpack/3.png)

<center><em>Webpack-Happypack</em></center>

`Happypack` 的处理思路是：将原有的 `webpack` 对 `loader` 的执行过程，从单一进程的形式扩展多进程模式，从而加速代码构建；原本的流程保持不变，这样可以在不修改原有配置的基础上，来完成对编译过程的优化，具体配置如下：

```
var HappyPack = require('happypack');
var happyThreadPool = HappyPack.ThreadPool({ size: os.cpus().length });
module: {
  loaders: [
    {
      test: /\.js[x]?$/,
      include: [resolve('src')],
      exclude: /node_modules/,
      loader: 'happypack/loader?id=happybabel'
    }
  ]
},
plugins: [
  new HappyPack({
    id: 'happybabel',
    loaders: ['babel-loader'],
    threadPool: happyThreadPool,
    cache: true,
    verbose: true
  })
]
```

可以研究看到，通过在 `loader` 中配置直接指向 `happypack` 提供的 `loader`，对于文件实际匹配的处理 loader，则是通过配置在 plugin 属性来传递说明，这里 `happypack` 提供的 `loader` 与 `plugin` 的衔接匹配，则是通过`id=happybabel`来完成。配置完成后，`laoder`的工作模式就转变成了如下所示：

![Webpack-Happypack](/img/webpack/4.png)

<center><em>Webpack-Happypack</em></center>

`Happypack` 在编译过程中，除了利用多进程的模式加速编译，还同时开启了 `cache` 计算，能充分利用缓存读取构建文件，对构建的速度提升也是非常明显的；更多关于 `happyoack` 个中原理，可参见 @淘宝前端团队(FED) 的这篇：[happypack 原理解析](https://taobaofed.org/blog/2016/12/08/happypack-source-code-analysis/)。如果你使用的 `Vue.js` 框架来开发，也可参考 [vue-webpack-happypack](https://github.com/nicejade/vue-boilerplate-template/blob/master/build/webpack.base.conf.js) 相关配置。

## 设置 babel 的 cacheDirectory 为true

[babel-loader](https://github.com/babel/babel-loader) is slow! 所以不仅要使用`exclude`、`include`，尽可能准确的指定要转化内容的范畴，而且要充分利用缓存，进一步提升性能。`babel-loader` 提供了 `cacheDirectory`特定选项（默认 `false`）：设置时，给定的目录将用于缓存加载器的结果。
未来的 `Webpack` 构建将尝试从缓存中读取，以避免在每次运行时运行潜在昂贵的 Babel 重新编译过程。如果值为空（`loader: ‘babel-loader?cacheDirectory’`）或`true（loader: babel-loader?cacheDirectory=true`），`node_modules/.cache/babel-loader` 则 `node_modules` 在任何根目录中找不到任何文件夹时，加载程序将使用默认缓存目录或回退到默认的OS临时文件目录。实际使用中，效果显著；配置示例如下：

```
rules: [
  {
    test: /\.js$/,
    loader: 'babel-loader?cacheDirectory=true',
    exclude: /node_modules/,
    include: [resolve('src'), resolve('test')]
  },
  ... ...
]
```

## 设置 [noParse](https://webpack.github.io/docs/configuration.html#module-noparse)

如果你确定一个模块中，没有其它新的依赖，就可以配置这项， `Webpack` 将不再扫描这个文件中的依赖，这对于比较大型类库，将能促进性能表现，具体可以参见以下配置：

```
module: {
  noParse: /node_modules\/(element-ui\.js)/,
  rules: [
    {
      ...
    }
}
```

## 拷贝静态文件

在前文 [Webpack 打包优化之体积](https://ningyu1.github.io/site/post/26-webpack1/)篇中提到，引入 `DllPlugin` 和 `DllReferencePlugin` 来提前构建一些第三方库，来优化 `Webpack` 打包。而在生产环境时，就需要将提前构建好的包，同步到 `dist` 中；这里拷贝静态文件，你可以使用 `copy-webpack-plugin` 插件：把指定文件夹下的文件复制到指定的目录；其配置如下：

```
var CopyWebpackPlugin = require('copy-webpack-plugin')
plugins: [
  ...
  // copy custom static assets
  new CopyWebpackPlugin([
    {
      from: path.resolve(__dirname, '../static'),
      to: config.build.assetsSubDirectory,
      ignore: ['.*']
    }
  ])
]
```

当然，这种工作，实现的法子很多，比如可以借助 `shelljs`，可以参见这里的实现 [vue-boilerplate-template](https://github.com/nicejade/vue-boilerplate-template/blob/master/build/build.js#L17-L22)。