# CentOS 自动备份脚本

一套基于 `cron` 的目录定时备份脚本，用于在 CentOS 系统上按天自动备份指定目录。

> ⚠️ 当前仅支持 CentOS 系统。

## 文件说明

| 文件 | 作用 |
| ---- | ---- |
| `daily_archive.sh` | 主配置脚本：指定备份目录、定时时间，并写入 crontab 定时任务 |
| `backup.sh` | 实际执行备份的脚本，由 cron 定时调用，自动读取配置 |
| `daily_archive.conf` | 配置文件（脚本首次运行后自动生成），保存目录、时间与日志路径 |
| `backup_cron.log` | 备份日志文件（自动生成） |

## 工作原理

1. 通过 `daily_archive.sh` 指定需要备份的目录和每日备份时间。
2. 配置会被持久化到同目录下的 `daily_archive.conf`。
3. 脚本将 `backup.sh` 加入 crontab，每天定时执行。
4. `backup.sh` 自动读取配置，使用 `tar -zcf` 将目标目录压缩为 `.tar.gz` 包，结果输出到日志。
5. 每次备份完成后，自动清理同目录下 **10 天前** 的旧备份文件，并将删除记录写入日志。

备份产物命名格式：`archive_<目录名>_<YYYYMMDDHHMMSS>.tar.gz`，与源目录位于同一父目录下。

## 使用方法

### 查看帮助

```bash
sh daily_archive.sh --help
```

### 1. 指定备份目录

```bash
sh daily_archive.sh /path/to/your/directory
```

- 尽量使用**绝对路径**。
- 未指定时间时，默认使用 `00:00` 执行。

### 2. 指定备份时间

```bash
sh daily_archive.sh 02:30
```

- 时间格式为 `hh:mm`（24 小时制），例如 `02:30`、`23:00`。

### 3. 查看定时任务

```bash
crontab -l
```

### 4. 手动执行一次备份

```bash
sh backup.sh
```

> 无需传参。`backup.sh` 会自动读取同目录下 `daily_archive.conf` 中的配置。请先通过 `daily_archive.sh` 完成目录与时间设置后再执行。

## 示例

假设要每天凌晨 3 点备份 `/data/www`：

```bash
# 1. 指定备份目录
sh daily_archive.sh /data/www

# 2. 指定备份时间
sh daily_archive.sh 03:00

# 3. 查看生成的定时任务
crontab -l
```

生成的 cron 任务形如：

```
0 3 * * * /path/to/backup.sh >> /path/to/backup_cron.log 2>&1 # daily_archive_job
```

每天凌晨 3 点，`/data` 下的 `www` 目录会被压缩为 `/data/archive_www_YYYYMMDDHHMMSS.tar.gz`。

## 注意事项

- 脚本需要与 `backup.sh` 位于同一目录下，否则无法识别备份脚本。
- 首次运行 `daily_archive.sh` 时会自动为 `backup.sh` 添加执行权限。
- 每次设置定时时间都会**先删除旧任务，再追加新任务**，避免重复写入。
- 备份文件默认保留 **10 天**，超期自动删除（当前暂不支持自定义保留时长）。
- 如需取消自动备份，可删除 crontab 中带有 `# daily_archive_job` 标记的任务：

```bash
crontab -l | grep -v "# daily_archive_job" | crontab -
```

## 许可证

[MIT](LICENSE)
