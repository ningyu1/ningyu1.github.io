---
title : "Fastdfs安装说明与常见问题解决"
description : "Fastdfs安装说明与常见问题解决"
tags : [
    "fastdfs"
]
date : "2017-07-04"
categories : [
    "fastdfs"
]
menu : "main"
---

# Fastdfs安装说明与常见问题解决

## docker中安装
``` bash
docker pull season/fastdfs
docker tag season/fastdfs 192.168.0.34:5000/season/fastdfs
docker push 192.168.0.34:5000/season/fastdfs
```
启动会获取tracker ip
`192.168.0.54:22122`

monitor检测
```
/usr/local/bin/fdfs_monitor /etc/fdfs/storage.conf
```

storage
store_path0路径与base_path路径必须不同

## 物理机安装
### 1.安装git
`yum install -y git`
### 2.下载fastdfs源码
``` bash
git clone https://github.com/happyfish100/fastdfs.git
git clone https://github.com/happyfish100/libfastcommon.git
git clone https://github.com/happyfish100/fastdfs-nginx-module.git
```
### 3.下载nginx
``` bash
cp /home/jyftp/nginx-1.10.1.tar.gz ./
tar -xvf nginx-1.10.1.tar.gz 
rm -rf nginx-1.10.1.tar.gz 
chown -R root.root nginx-1.10.1/
mv nginx-1.10.1/ nginx
```
### 4.安装libfastcommon (fastdfs依赖的系统库）
``` bash
cd /usr/local/fastdfs/libfastcommon
./make.sh
./make.sh install
```
### 5.安装fastdfs
``` bash
cd /usr/local/fastdfs/fastdfs
./make.sh
./make.sh install
```
### 6.安装nginx
``` bash
cd /usr/local/nginx
./configure --prefix=/usr/local/nginx --conf-path=/usr/local/nginx/nginx.conf --add-module=/usr/local/fastdfs/fastdfs-nginx-module/src
make 
make install
```
安装nginx错误处理
错误信息：
```
./configure: error: the HTTP rewrite module requires the PCRE library. 
```
安装pcre-devel与openssl-devel解决问题，执行下面命令
```
yum -y install pcre-devel openssl openssl-devel
```
错误信息：
```
/data/soft/fastdfs-nginx-module/src/ngx_http_fastdfs_module.c:894: 错误：‘struct fdfs_http_context’没有名为‘if_modified_since’的成员
/data/soft/fastdfs-nginx-module/src/ngx_http_fastdfs_module.c:897: 错误：‘struct fdfs_http_context’没有名为‘if_modified_since’的成员
/data/soft/fastdfs-nginx-module/src/ngx_http_fastdfs_module.c:927: 错误：‘struct fdfs_http_context’没有名为‘range’的成员
/data/soft/fastdfs-nginx-module/src/ngx_http_fastdfs_module.c:933: 错误：‘struct fdfs_http_context’没有名为‘if_range’的成员
/data/soft/fastdfs-nginx-module/src/ngx_http_fastdfs_module.c:933: 错误：‘true’未声明(在此函数内第一次使用)
make[1]: *** [objs/addon/src/ngx_http_fastdfs_module.o] 错误 1
make[1]: Leaving directory `/data/soft/nginx-1.8.0'
make: *** [build] 错误 2
```
解决办法
执行以下2条命令，然后重新make
```
ln -sv /usr/include/fastcommon /usr/local/include/fastcommon
ln -sv /usr/include/fastdfs /usr/local/include/fastdfs
```
拷贝相关文件到/etc/fdfs目录下：
```
cp /usr/local/fastdfs/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs/
cp /usr/local/fastdfs/fastdfs/conf/mime.types /etc/fdfs/
cp /usr/local/fastdfs/fastdfs/conf/http.conf /etc/fdfs/
cp /usr/local/fastdfs/fastdfs/conf/anti-steal.jpg /etc/fdfs/
```
如果是下面错误，需要安装fastdfs最新版，直接从github上下载源码安装
```
local/fastdfs-nginx-module/src/common.c:1245: 错误：‘FDFSHTTPParams’没有名为‘support_multi_range’的成员
make[1]: *** [objs/addon/src/ngx_http_fastdfs_module.o] 错误 1
make[1]: Leaving directory `/usr/local/nginx-1.10.1'
```
解决办法：github上下载最新FastDFS master源码，重新编译安装即可。

### 7.配置fastdfs
#### 7.1 创建数据存放目录（用于存放数据）
``` bash
cd /usr/local/fastdfs
mkdir fast_data
cd fast_data
```
##### tracker基础数据和日志
```
mkdir tracker
```
##### storage基础数据和日志
```
mkdir storage
```
##### storage 数据存放目录
```
mkdir store_path
```
##### fast nginx模块基础数据和日志
```
mkdir nginx_module
```
#### 7.2 创建配置文件目录（用于存放使用的配置文件）
```
mkdir fast_conf
cd /usr/local/fastdfs/fastdfs/conf
cp ./* /usr/local/fastdfs/fast_conf/
```
#### 7.3 配置tracker
##### 编辑basepath
```
＃basepath(用于存放tracker的基本数据，包括日志）
base_path=/usr/local/fastdfs/fast_data/tracker
```
#### 7.4 配置storage
##### 修改如下配置：
```
＃用于存储storage基本数据的目录（包括日志）
base_path=/usr/local/fastdfs/fast_data/storage
＃数据存放的目录
store_path0=/usr/local/fastdfs/fast_data/store_path
＃group的名字
group_name=group1
# tracker地址
tracker_server=10.30.193.163:22122
```
##### 这个是tracker的ip地址和端口号
`tracker_server=192.168.0.48:22122`
#### 7.5 修改nginx相关的fastdfs配置文件 
将nginx module的配置文件拷贝到fastdfs的配置目录
```
cp /usr/local/fastdfs/fastdfs-nginx-module/src/mod_fastdfs.conf /usr/local/fastdfs/fast_conf
```
修改mod_fastdfs.conf
```
#存放日志等文件
base_path=/usr/local/fastdfs/fast_data/nginx_module
#tracker的地址（这个是nginx中的plugin使用的）
tracker_server=192.168.0.48:22122
#本地对应的group名字（当前nginx对应的storage存储的group的名字）
group_name=group1
#这个配置用于说明nginx对应的storage存储文件的实际位置
store_path0=/usr/local/fastdfs/fast_data/store_path
#这个是url是否需要带groupname
url_have_group_name = true
```
#### 9. 编写启动脚本
```
cd /usr/local/fastdfs
```
#### 9.1 创建 启动文件目录
```
mkdir bin
```
tracker的启动脚本 
##### 9.2 在bin目录下，创建tracker.sh 
``` bash
#!/bin/sh

case "$1" in

    start) 
	/usr/local/fastdfs/fastdfs/tracker/fdfs_trackerd /usr/local/fastdfs/fast_conf/tracker.conf
    ;;
    stop) 
	/usr/local/fastdfs/fastdfs/tracker/fdfs_trackerd /usr/local/fastdfs/fast_conf/tracker.conf stop
    ;;
    restart)
	/usr/local/fastdfs/fastdfs/tracker/fdfs_trackerd /usr/local/fastdfs/fast_conf/tracker.conf restart 
    ;;

esac   

# tailf /usr/local/fastdfs/fast_data/tracker/logs/trackerd.log

exit 0
```
将文件变成可执行
```
chmod +x tracker.sh
```
##### 9.3 在bin目录下，创建storage.sh
``` bash
#!/bin/sh

case "$1" in

    start)
	/usr/local/fastdfs/fastdfs/storage/fdfs_storaged /usr/local/fastdfs/fast_conf/storage.conf 
    ;;
    stop)
	/usr/local/fastdfs/fastdfs/storage/fdfs_storaged /usr/local/fastdfs/fast_conf/storage.conf stop 
    ;;
    restart)
	/usr/local/fastdfs/fastdfs/storage/fdfs_storaged /usr/local/fastdfs/fast_conf/storage.conf restart
    ;;

esac   

# tailf /usr/local/fastdfs/fast_data/storage/logs/storaged.log

exit 0
```
将文件变成可执行
```
chmod +x storage.sh
```
##### 9.4 配置、启动nginx
修改`mod_fastdfs.conf`配置文件
```
cd /usr/local/fastdfs/fast_conf/
vi mod_fastdfs.conf
```

``` bash
# FastDFS tracker_server can ocur more than once, and tracker_server format is
#  "host:port", host can be hostname or ip address
# valid only when load_fdfs_parameters_from_tracker is true
tracker_server=192.168.0.48:22122

# the port of the local storage server
# the default value is 23000
storage_server_port=23000

# if the url / uri including the group name
# set to false when uri like /M00/00/00/xxx
# set to true when uri like ${group_name}/M00/00/00/xxx, such as group1/M00/xxx
# default value is false
url_have_group_name = true

# store_path#, based 0, if store_path0 not exists, it's value is base_path
# the paths must be exist
# must same as storage.conf
store_path0=/usr/local/fastdfs/fast_data/store_path
#store_path1=/home/yuqing/fastdfs1
```
copy配置文件到 `/etc/fdfs`下
``` bash
cd /usr/local/fastdfs/fast_conf/
cp anti-steal.jpg http.conf mime.types mod_fastdfs.conf /etc/fdfs/
```
修改nginx的配置文件
``` bash
cd /usr/local/nginx
vi nginx.conf
server {
listen 8079;
	location ~/M00 {
	    root /usr/local/fastdfs/fast_data/store_path/data;
	    ngx_fastdfs_module;
	}
}
```
创建软连接
```
ln -s /usr/local/fastdfs/fast_data/store_path/data /usr/local/fastdfs/fast_data/store_path/data/M00
```
启动nginx之前先-t检查一下配置文件是否有错误
```
/usr/local/nginx/sbin/nginx -t
```
输出一下信息表示正确
``` 
[root@localhost bin]# /usr/local/nginx/sbin/nginx -t
ngx_http_fastdfs_set pid=125936
nginx: the configuration file /usr/local/nginx/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/nginx.conf test is successful
```
启动nginx
```
/usr/local/nginx/sbin/nginx
```
启动 Nginx 后会打印出fastdfs模块的pid，看看日志是否报错，正常不会报错的
``` bash
[root@localhost fdfs]# /usr/local/nginx/sbin/nginx
ngx_http_fastdfs_set pid=126276
```

#### 遇到的错误
错误：
```
ERROR - file: storage_ip_changed_dealer.c, line: 186, connect to tracker server 172.0.0.1:22122 fail, errno: 110, error info: Connection timed out
```
防火墙中打开tracker服务器端口（ 默认为 22122）
```
vi /etc/sysconfig/iptables 
```
附加：若/etc/sysconfig 目录下没有iptables文件可随便写一条iptables命令配置个防火墙规则：如：
```
iptables -P OUTPUT ACCEPT
```
然后用命令：service iptables save 进行保存，默认就保存到 /etc/sysconfig/iptables 文件里。这时既有了这个文件。防火墙也可以启动了。接下来要写策略，也可以直接写在/etc/sysconfig/iptables 里了。
添加如下端口行： 
``` bash
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22122 -j ACCEPT 
-A INPUT -m state --state NEW -m tcp -p tcp --dport 23000 -j ACCEPT 
-A INPUT -m state --state NEW -m tcp -p tcp --dport 8079 -j ACCEPT 
# 22122 tracker 端口
# 23000 storage 端口
# 8079 nginx listen端口
```
重启防火墙
```
service iptables restart
```

#### Fastdfs Client测试

执行命令
```
/usr/bin/fdfs_test /usr/local/fastdfs/fast_conf/client.conf  upload /usr/local/fastdfs/fast_conf/
```
输出
``` bash
This is FastDFS client test program v5.11

Copyright (C) 2008, Happy Fish / YuQing

FastDFS may be copied only under the terms of the GNU General
Public License V3, which may be found in the FastDFS source kit.
Please visit the FastDFS Home Page http://www.csource.org/ 
for more detail.

[2017-05-16 14:03:07] DEBUG - base_path=/usr/local/fastdfs/fast_data, connect_timeout=30, network_timeout=60, tracker_server_count=1, anti_steal_token=0, anti_steal_secret_key length=0, use_connection_pool=0, g_connection_pool_max_idle_time=3600s, use_storage_id=0, storage server id count: 0

tracker_query_storage_store_list_without_group: 
	server 1. group_name=, ip_addr=192.168.0.48, port=23000

group_name=group1, ip_addr=192.168.0.48, port=23000
storage_upload_by_filename
group_name=group1, remote_filename=M00/00/00/wKgAMFkalhuARwsaAAAFvLZ-36489.conf
source ip address: 192.168.0.48
file timestamp=2017-05-16 14:03:07
file size=1468
file crc32=3061768110
example file url: http://192.168.0.48/group1/M00/00/00/wKgAMFkalhuARwsaAAAFvLZ-36489.conf
storage_upload_slave_by_filename
group_name=group1, remote_filename=M00/00/00/wKgAMFkalhuARwsaAAAFvLZ-36489_big.conf
source ip address: 192.168.0.48
file timestamp=2017-05-16 14:03:08
file size=1468
file crc32=3061768110
example file url: http://192.168.0.48/group1/M00/00/00/wKgAMFkalhuARwsaAAAFvLZ-36489_big.conf
```

#### 查看Fastdfs集群监控信息
执行命令
```
/usr/bin/fdfs_monitor /usr/local/fastdfs/fast_conf/client.conf
```
输出
``` bash
[2017-05-16 14:17:38] DEBUG - base_path=/usr/local/fastdfs/fast_data, connect_timeout=30, network_timeout=60, tracker_server_count=1, anti_steal_token=0, anti_steal_secret_key length=0, use_connection_pool=0, g_connection_pool_max_idle_time=3600s, use_storage_id=0, storage server id count: 0

server_count=1, server_index=0

tracker server is 192.168.0.48:22122

group count: 1

Group 1:
group name = group1
disk total space = 46161 MB
disk free space = 33446 MB
trunk free space = 0 MB
storage server count = 1
active server count = 1
storage server port = 23000
storage HTTP port = 8888
store path count = 1
subdir count per path = 256
current write server index = 0
current trunk file id = 0

	Storage 1:
		id = 192.168.0.48
		ip_addr = 192.168.0.48  ACTIVE
		http domain = 
		version = 5.11
		join time = 2017-05-16 11:40:48
		up time = 2017-05-16 13:04:57
		total storage = 46161 MB
		free storage = 33446 MB
		upload priority = 10
		store_path_count = 1
		subdir_count_per_path = 256
		storage_port = 23000
		storage_http_port = 8888
		current_write_path = 0
		source storage id = 
		if_trunk_server = 0
		connection.alloc_count = 256
		connection.current_count = 0
		connection.max_count = 2
		total_upload_count = 3
		success_upload_count = 3
		total_append_count = 0
		success_append_count = 0
		total_modify_count = 0
		success_modify_count = 0
		total_truncate_count = 0
		success_truncate_count = 0
		total_set_meta_count = 3
		success_set_meta_count = 3
		total_delete_count = 0
		success_delete_count = 0
		total_download_count = 0
		success_download_count = 0
		total_get_meta_count = 0
		success_get_meta_count = 0
		total_create_link_count = 0
		success_create_link_count = 0
		total_delete_link_count = 0
		success_delete_link_count = 0
		total_upload_bytes = 4738
		success_upload_bytes = 4738
		total_append_bytes = 0
		success_append_bytes = 0
		total_modify_bytes = 0
		success_modify_bytes = 0
		stotal_download_bytes = 0
		success_download_bytes = 0
		total_sync_in_bytes = 0
		success_sync_in_bytes = 0
		total_sync_out_bytes = 0
		success_sync_out_bytes = 0
		total_file_open_count = 3
		success_file_open_count = 3
		total_file_read_count = 0
		success_file_read_count = 0
		total_file_write_count = 3
		success_file_write_count = 3
		last_heart_beat_time = 2017-05-16 14:17:31
		last_source_update = 2017-05-16 14:14:16
		last_sync_update = 1970-01-01 08:00:00
		last_synced_timestamp = 1970-01-01 08:00:00 
```
