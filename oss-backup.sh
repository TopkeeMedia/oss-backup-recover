#!/usr/bin/env bash

# 接收参数 $1 要备份的数据集
pool=`zpool status| grep pool: | grep -v boot-pool | cut -d : -f 2|sed -e 's/\(^ *\)//'`

dateset=$1
pooldateset="$pool/$dateset@auto"
# 快照名称数组
arr=();
echo "数据池备份"
echo "数据池：$pool"
echo "数据集：$dateset"
echo "快照基准名：$pooldateset"
source_path="/mnt/$pool/$dateset"
if [ ! -d ${source_path} ];
then
 echo "要备份的数据集不存在: $source_path 停止执行"
 exit
fi


backup_path="/mnt/$pool/autobackup"
echo "存储目录: $backup_path"
if [ ! -d ${backup_path} ];
then
 echo "存储目录不存在: $backup_path 自动创建"
 `zfs create $pool/autobackup`
fi

# echo $(date -v -1H +$pooldateset-%Y-%m-%d_%H)
t_now=$(date +$pooldateset-%Y-%m-%d_%H)
# echo $t_now

this_month=$(date +auto-%Y-%m)
last_month=$(date -v -1m +auto-%Y-%m)
last2_month=$(date -v -2m +auto-%Y-%m)
last3_month=$(date -v -3m +auto-%Y-%m)

echo "月份 $this_month $last_month $last2_month $last3_month"

#funtion 读取快照列表
read_snap()
{
    echo "---本月快照列表---------------";
    for snap in `zfs list -t snap | grep $this_month`
    do
        if [[ $snap == *$pooldateset* ]]
        then
        arr+=($snap)
        fi
       
    done
    
}
read_snap
# 当前快照
if [[ ${arr[@]/${t_now}/} != ${arr[@]} ]] 
then
 echo "已存在快照: $t_now"
else
 echo "创建快照: $t_now"
 zfs snap $t_now
 arr+=($t_now)
fi
echo "当前快照列表: ${arr[@]}"

temp="";

# 遍历快照
echo "---生成文件------------"
for element in ${arr[@]}
#也可以写成for element in ${array[*]}
do
    if ([[ $temp = "" ]])
    then
    temp=$element
    # 全量包
    snap1=`echo $temp | cut -d @ -f 2`
    all_file="$backup_path/$snap1.gz"
    echo "全量包 $all_file"
        if [ ! -f ${all_file} ];
        then
            echo "创建全量包 $all_file"
            zfs send $element | gzip > $all_file
        fi

    else
        snap1=`echo $temp | cut -d @ -f 2`
        snap2=`echo $element | cut -d @ -f 2`
        temp_file="$backup_path/$snap1#$snap2.gz"
        echo "增量包 $temp_file"
        if [ ! -f ${temp_file} ];
        then
            echo "创建增量包 $temp_file"
            zfs send -i $temp $element | gzip > $temp_file
        else
            echo "已存在，不创建"
        fi
        temp=$element
    fi

done

#funtion 删除旧的文件
delete_old_file()
{
    un_include="$this_month|$last_month|$last2_month|config";
    echo "---旧文件查询--------排除这些：$un_include"
    for old_file in `ls $backup_path | grep -vE $un_include`
    do
       old_file_path="$backup_path/$old_file";
       `rm $old_file_path`
       echo "旧文件删除：$old_file_path"
    done
    
}
delete_old_file

#funtion 旧快照清理
delete_old_snaps()
{
    echo "---旧快照删除------------"
    for old_snap in `zfs list -t snap | grep $last3_month`
    do
        if [[ $old_snap == *$last3_month* ]]
        then
        `zfs destroy $old_snap`
        echo "旧快照删除：$old_snap"
        fi
       
    done
    
}
delete_old_snaps

echo "备份完成"