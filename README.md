# this is blog source branch

# 修改主题的地方

1. 修改indigo\languages 知识共享licenses
2. 修改indigo\layout\_partial\post\toc.ejs 目录名称
3. 修改indigo\source\img 头像与打赏图片
4. 修改indigo\_config.yml 归档、分类、标签 目录，评论等配置
5. 修改indigo\source\js\main.js 修改打赏遮罩问题 https://github.com/yscoder/hexo-theme-indigo/pull/355/

# hexo-asset-image

1. 修改index.js 增加post_asset_folder=custom生成文章图片增加root目录

_ps. 修改后的publish到npmjs，名称：hexo-asset-image-ny，版本：0.0.3_

# hexo-generator-baidu-sitemap

1. 修改baidusitemap.ejs，去掉多余的root

_ps. 修改后的publish到npmjs，名称：hexo-generator-baidu-sitemap-ny1，版本：0.1.6_

# 其他修改

1. 采用知识共享署名-相同方式共享 4.0 国际许可协议
2. 赞赏样式调整
3. 评论采用gitalk
4. 增加百度站长校验

# mac下安装hexo

```shell script
npm install -g hexo_cli
```

ps.如果报错使用`--save`

```shell script
npm install hexo --save
```

安装后采用npx run Hexo

```shell script
npx hexo generate
```

# 小技巧

排除文件提交不通知travis构建
```shell script
git commit -m "updated readme [skip ci]"
```

本地测试`.travis.yml`配置正确性
```shell script
docker run -it -u travis quay.io/travisci/travis-${xxx} /bin/bash
```
创建一个docker容器挂在本地文件，并将能够在该容器内安装的文件夹中执行travis compile.

各语言的镜像列表
```
https://quay.io/repository/travisci/travis-android
https://quay.io/repository/travisci/travis-erlang
https://quay.io/repository/travisci/travis-go
https://quay.io/repository/travisci/travis-haskell
https://quay.io/repository/travisci/travis-jvm
https://quay.io/repository/travisci/travis-node-js
https://quay.io/repository/travisci/travis-perl
https://quay.io/repository/travisci/travis-php
https://quay.io/repository/travisci/travis-python
https://quay.io/repository/travisci/travis-ruby
```

ps.以上来自[镜像地址](https://gist.github.com/solarce/9642ed12f4fcc8d118a9)
