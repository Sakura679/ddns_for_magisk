#!/system/bin/sh

(
  # 等待开机完成，最多等 120 秒
  WAIT=0
  until [ "$(getprop init.svc.bootanim)" = "stopped" ] || [ $WAIT -ge 12 ]; do
      sleep 10
      WAIT=$((WAIT + 1))
  done

  if [ $WAIT -ge 12 ]; then
      echo -t ipv6-ddns "等待开机完成超时，强制继续"
  fi

  if [ -f "/data/adb/modules/ipv6-ddns/ddns.sh" ]; then
    chmod 755 /data/adb/modules/ipv6-ddns/ddns.sh
    nohup sh /data/adb/modules/ipv6-ddns/ddns.sh > /dev/null 2>&1 &
    echo "运行成功"
  else
    echo "未找到文件 '/data/adb/modules/ipv6-ddns/ddns.sh'"
  fi
)&
