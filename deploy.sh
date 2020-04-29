#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e

# 生成静态文件
hexo g

# 进入生成的文件夹
cd ./public

#创建.nojekyll 防止Github Pages build错误
touch .nojekyll

git init
git config user.name "ningyu"
git config user.email "ningbe111@163.com"
git add .
git commit -m "Deploy blog"
git push -f "https://${access_token}@github.com/ningyu1/blog.git" master:master

cd -