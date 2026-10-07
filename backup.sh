#!/bin/sh

# 备份脚本


# 接收参数
CONF_FILE="$(dirname "$(readlink -f "$0")")/daily_archive.conf"
[ -f "$CONF_FILE" ] && . "$CONF_FILE"
export LOG_FILE

DIR=${DIR_PATH}/$DIR_NAME

# 获取当前时间
TIME=$(date +%Y%m%d%H%M%S)

# 备份文件
FILENAME=archive_${DIR_NAME}_$TIME
DEST=$DIR_PATH/$FILENAME

# 备份
echo "${TIME},开始备份..."
tar -zcf "${DEST}.tar.gz" -C "$(dirname "$DIR")" "$(basename "$DIR")"

if [ $? -eq 0 ]
then
	echo "备份成功！备份文件：$DEST"
else
	echo "备份失败！请退出重试"
	exit 1
fi

# 删除文件
# 默认自动删除十天前的备份文件（暂无法设置自定义时间，待更新...）
find "${DIR_PATH}" -type f -mtime +10 -name "archive_${DIR_NAME}_*.tar.gz" \
-exec sh -c '
	for file; do
		echo "$(date "+%Y-%m-%d %H:%M:%S") 删除: $file" >> "$LOG_FILE"
		rm -f -- $file
	done
' _ {} +  
