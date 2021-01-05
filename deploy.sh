#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e

function error_exit {
  echo "$1" 1>&2
  exit 1
}

# 生成静态文件
hexo generate

# 验证hexo生成是否成功
if [ ! -d "./public" ]; then
  error_exit "生成失败，无public文件夹"!
fi
if [ ! -f "./public/index.html" ]; then
  error_exit "生成失败，无index.html文件"!
fi

# 获取文件大小
file_size=`wc -c "./public/index.html" | awk '{print $1}'`

if [ $file_size -le 0 ]; then
  error_exit "生成失败，生成的文件大小为0"!
fi

# 进入生成的文件夹
cd ./public

#创建.nojekyll 防止Github Pages build错误
touch .nojekyll

git init
git config user.name "ningyu1"
git config user.email "ningbe111@163.com"
git add -A .
git commit -m "Update blog"
git push -f "https://${access_token}@github.com/ningyu1/blog.git" master:master

cd -