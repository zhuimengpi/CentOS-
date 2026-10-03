#!/bin/sh

# 备份脚本

# 接收参数
DIR_PATH=$1
DIR_NAME=$2
DIR=${DIR_PATH}/$DIR_NAME

# 获取当前时间
TIME=$(date +%Y%m%d)

# 备份文件
FILENAME=archive_${DIR_NAME}_$TIME
DEST=$DIR_PATH/$FILENAME

# 备份
echo "${TIME},开始备份..."
cp -a $DIR $DEST

if [ $? -eq 0 ]
then
	echo "备份成功！备份文件：$DEST"
else
	echo "备份失败！请退出重试"
	exit 1
fi

