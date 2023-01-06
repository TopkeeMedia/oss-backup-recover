#!/usr/bin/env bash

# 接收参数 
# $1 要恢复到哪一个数据集
# $2 要还原的起始包

pool=`zpool status| grep pool: | grep -v boot-pool | cut -d : -f 2|sed -e 's/\(^ *\)//'`
echo "数据池还原"

echo "---参数校验开始------------"
dataset=$1

dataset_full_path="$pool/$dataset";
start_file_path=$2
#删除从右边开始到指定字符第一次出现的字符并保留左边字符
backup_path=`echo ${start_file_path%/*}`

start_file=`echo ${start_file_path##*/}`
start_file=`echo ${start_file%.*}`
echo "数据池 $pool"
echo "还原到数据集 $dataset"
echo "起始备份 $start_file_path"
echo "路径 $backup_path"
echo "备份名 $start_file"
# echo "为了还原能正常进行，请确保数据集 $dataset_full_path 没有本地快照"

#funtion 删除旧快照
delete_snap()
{
    echo "---删除旧快照开始---------------";
    for old_snap in `zfs list -t snap | grep $dataset_full_path@`
    do
        if [[ $old_snap == *$dataset_full_path* ]]
        then
            if [[ $old_snap == *$last3_month* ]]
            then
            `zfs destroy $old_snap`
            echo "旧快照删除：$old_snap"
            fi
        fi
       
    done
    
}
delete_snap
echo "---删除旧快照完成---------------";


if [ ! -f ${start_file_path} ];
then
 echo "备份不存在: $start_file_path 停止执行"
 exit
fi
echo "---参数校验完成------------"

`gunzip -c $start_file_path | zfs receive -F $dataset_full_path`

cd $backup_path
pwdd=`pwd`
echo "当前路径 $pwdd"
echo "---遍历备份包开始------------"
while [[ -n $start_file ]]
do
    echo $start_file
    next_file=`ls | grep \# | grep ^$start_file`
    echo "下一个备份 $next_file"
    start_file="";
    if [[ -n $next_file ]]
    then
      `gunzip -c $backup_path/$next_file | zfs receive -F $dataset_full_path`
       echo "已还原备份 $next_file"
      start_file=`echo ${next_file%.*}`
      start_file=`echo ${start_file##*\#}`
    fi
   
done


echo "---遍历备份包完成------------"

echo "还原完成"

