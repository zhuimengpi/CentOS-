#!/bin/sh
# 目录定时备份脚本

# !当前仅支持CentOS系统

# 接收参数
# --help 帮助
# filename 目录名称	$DIR_PATH + $DIR_NAME
# time 定时执行时间	DAILY_TIME

# 配置文件
CONF_FILE="$(dirname "$(readlink -f "$0")")/daily_archive.conf"
# 备份脚本
WORK_SH="$(dirname "$(readlink -f "$0")")/backup.sh"
# 默认定时时间
DEFAULT_TIME="00:00"
# 录入日志参数
TAG="# daily_archive_job"
# 备份日志
LOG_FILE="$(dirname "$(readlink -f "$0")")/backup_cron.log"

# ---------- 载入已保存的配置 ----------
[ -f "$CONF_FILE" ] && . "$CONF_FILE"

# 参数判断
# 1.参数数量为1
if [ $# -ne 1 ]
then
	echo "本脚本仅支持单个参数，请使用\"sh daily_archive.sh --help 进行参数查询\""
	exit 1
fi

# 2.参数类型匹配
option="$1"
case "$option" in
# 帮助文档
"--help")
	echo "1.指定备份目录名称：\"sh daily_archive.sh filename\""
	echo "注意：filename尽量使用绝对路径"
	echo "2.指定定时备份时间：\"sh daily_archive.sh time\""
	echo "注意：时间格式为hh:mm"
	exit 
;;
# 定时设置
0[0-9]:[0-5][0-9] | 1[0-9]:[0-5][0-9] | 2[0-3]:[0-5][0-9])
	#判断是否指定目录
	if [ -z "$DIR_PATH" ] || [ -z "$DIR_NAME" ]; then
        echo "尚未指定备份目录，请先执行目录指定！"
        exit 1
    	fi	

	DAILY_TIME=$option
	echo "已设置每日 ${DAILY_TIME} 执行备份"
;;
# 目录设置
*)
	# 判断目录是否正确
	if [ ! -d "$option" ]
	then
		echo "目录不存在！"
		exit 1
	fi

	# 备份目录
	DIR_NAME=$(basename "$option")
	DIR_PATH=$(cd "$(dirname "$option")"; pwd)

	# 默认时间
	if [ -z "$DAILY_TIME" ]; then
        DAILY_TIME="$DEFAULT_TIME"
        echo "未指定定时时间，使用默认时间 ${DAILY_TIME}"
    	fi

	echo "已设置备份目录：${DIR_PATH}/${DIR_NAME}"
;;
esac

# -------判断是否指定目录----------
if [ -z "$DIR_NAME" ]
then
	echo "请先指定备份目标，再运行程序！"
	exit 1
fi

# ---------- 持久化配置 ----------
{
    echo "DAILY_TIME=\"$DAILY_TIME\""
    echo "DIR_PATH=\"$DIR_PATH\""
    echo "DIR_NAME=\"$DIR_NAME\""
    echo "LOG_FILE=\"$LOG_FILE\""
} > "$CONF_FILE"

# ---------识别备份脚本----------
if [ ! -f "$WORK_SH" ]
then
	echo "无法识别backup.sh，运行失败！"
	exit 1
fi

# -------备份脚本执行权限--------
if [ -f "$WORK_SH" ]; then
    if ! chmod +x "$WORK_SH" 2>/dev/null; then
        echo "警告：无法为 $WORK_SH 添加执行权限，请手动执行："
        echo "chmod +x $WORK_SH"
        exit 1
    fi
else
    echo "备份脚本不存在：$WORK_SH"
    exit 1
fi

#----------  定时任务 -----------
if [ -n "$DAILY_TIME" ] && [ -n "$DIR_PATH" ]
then
	# 提前创建backup_cron.log
	[ -f "$LOG_FILE" ] || touch "$LOG_FILE"

	# 时间确定
	HOUR=${DAILY_TIME%%:*}
	MINUTE=${DAILY_TIME##*:}
	CRON_TIME="$MINUTE $HOUR * * *"
	CRON_LINE="$CRON_TIME $WORK_SH >> $LOG_FILE 2>&1 $TAG"

	# 执行脚本、记录日志（同时删除旧任务，追加新任务）
	( crontab -l 2>/dev/null | grep -v "$TAG"; echo "$CRON_LINE" ) | crontab -
	echo "cron 任务已更新: $CRON_LINE"
else
	echo "信息不完整，暂未写入 cron（需同时具备目录和时间）"
fi
