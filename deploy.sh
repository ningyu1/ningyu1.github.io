#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e

# 生成静态文件
hexo generate --watch

# 进入生成的文件夹
cd ./public

#创建.nojekyll 防止Github Pages build错误
touch .nojekyll

git init
git add -A
git commit -m "deploy"
git push -f "https://${access_token}@github.com/ningyu1/blog.git" master:master

cd -