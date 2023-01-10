# 备份
1. 运行脚本oss-backup.sh，生成备份包
2. 设置云同步任务，将备份包备份到云端，备份完成

## 拷贝脚本
将oss-backup.sh拷贝到要备份的机器里，一般用ssh
## 授予权限
chmod +x ./oss-backup.sh 
## 定时生成备份
nas添加每小时一次的计划任务，运行命令为 /root/test/oss-backup.sh s3 其中s3是要备份的数据集，该任务每小时生成一个增量备份包
## 定时云存储备份
设置一个（push+ async）的云同步任务，将本地的备份包同步到云端



# 还原
1. 将云端备份包拉取到备用机
2. 运行脚本oss-recover.sh，还原完成

## 设置rclone
rclone config 选择n新建一个配置，前面备份在哪里，这个配置就指向哪里，比如我加了一个名为aliyun的配置
## 拉取备份包
rclone sync aliyun:bucket_name/bucket_name/hk1   /mnt/PoolNS/savegz/
备份包在bucket_name存储桶的/bucket_name/hk1路径下
备份包会被拉取到 /mnt/PoolNS/savegz/ 数据集里
## 拷贝脚本
将oss-recover.sh拷贝到要备份的机器里，一般用ssh
## 授予权限
chmod +x ./oss-recover.sh
## 备份还原
./oss-recover.sh s3rec /mnt/PoolNS/savegz/auto-2023-01-03_00.gz
备份会还原到数据集 s3rec ，数据集名字可自行指定
/mnt/PoolNS/savegz/auto-2023-01-03_00.gz 是你要还原的第一个备份包，必须指定

## 还原过程

还原auto-2023-01-03_00.gz后，
脚本会找到下一个还原包auto-2023-01-03_00#auto-2023-01-03_01.gz 

还原auto-2023-01-03_00#auto-2023-01-03_01.gz后，
脚本会找到下一个还原包auto-2023-01-03_01#auto-2023-01-03_19.gz 

依此类推...

还原auto-2023-01-03_00#auto-2023-01-03_01.gz后，
脚本找不到下一个还原包，还原结束

## 备份包保存格式：
auto-2023-01-03_00.gz                           
auto-2023-01-03_00#auto-2023-01-03_01.gz  
auto-2023-01-03_01#auto-2023-01-03_19.gz  
auto-2023-01-03_19#auto-2023-01-03_20.gz   
auto-2023-01-03_20#auto-2023-01-05_00.gz     
auto-2023-01-05_10#auto-2023-01-05_11.gz



## 问答

1. 备份周期为多长

一个月，是为了方便备份包文件名的组织

2. 保留几个周期

2-3个，比如现在备份周期是2023-01，会保留2023-01，2022-12，2022-11，2033-10的备份包和快照将被脚本删除

3. 还原时遇到cannot unmount '/mnt/xxx': pool or dataset is busy提示

这是由于要还原的数据集正在使用，比如正在被s3使用，请让其处于不在使用状态再还原


