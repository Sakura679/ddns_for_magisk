#!/system/bin/sh

# 模块目录和日志文件
MODDIR="/data/adb/modules/ipv6-ddns"
LOG_FILE="$MODDIR/run.log"

# 日志函数：同时输出到控制台和日志文件
log_msg() {
    local msg="$1"
    echo "[ddns-service] $msg"
    [ "$ENABLE_LOG" = true ] && echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

(
  # 等待开机完成，最多等 120 秒
  WAIT=0
  until [ "$(getprop init.svc.bootanim)" = "stopped" ] || [ $WAIT -ge 12 ]; do
      sleep 10
      WAIT=$((WAIT + 1))
  done

  if [ $WAIT -ge 12 ]; then
      log_msg "等待开机完成超时，强制继续"
  fi

  if [ -f "$MODDIR/ddns.sh" ]; then
    chmod 755 "$MODDIR/ddns.sh"
    nohup sh "$MODDIR/ddns.sh" > /dev/null 2>&1 &
    log_msg "运行成功"
  else
    log_msg "未找到文件 '$MODDIR/ddns.sh'"
  fi
)&
