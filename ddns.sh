#!/system/bin/sh

MODDIR=${0%/*}

# 加载配置
. "$MODDIR/config.sh"

# 日志文件
LOG_FILE="$MODDIR/run.log"

# 日志函数：同时输出到控制台和日志文件
log() {
    tee -a "$LOG_FILE"
}

# 日志轮转：如果日志文件超过1MB，保留最后500行
rotate_log() {
    local max_size=$((1024 * 1024)) # 1MB
    if [ -f "$LOG_FILE" ]; then
        local size=$(wc -c < "$LOG_FILE")
        if [ "$size" -gt "$max_size" ]; then
            tail -n 500 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
        fi
    fi
}

# 初始化日志轮转
rotate_log

while true; do
    # 1. 获取所有全局单播 IPv6 地址列表（兼容 toybox/grep 无 -P）
    IP6_LIST=$(ip -6 addr show wlan0 scope global | grep 2408 2>/dev/null |
            awk '/inet6/ {gsub(/\/.*/, "", $2); print $2}')

    # 2. 无 IPv6 直接下一轮
    if [ -z "$IP6_LIST" ]; then
        log "未获取到全局 IPv6，等待下一轮"
        sleep $CHECK_INTERVAL
        continue
    fi

    # 3. IP 列表与上次 DDNS 的 IP 比较
    if [ "$IP6_LIST" = "$LAST_DDNS_IP6_LIST" ]; then
        log "IPv6 列表未变化，跳过 DDNS 更新"
        sleep $CHECK_INTERVAL
        continue
    fi

    # 4. 检测到变化，从新列表中取出变化的 IP（只取一个）
    log "检测到 IPv6 变化，准备更新 DDNS"
    IP6=$(echo "$IP6_LIST" | while read ip; do
        if ! echo "$LAST_DDNS_IP6_LIST" | grep -q "^$ip$"; then
            echo "$ip"
            break  # 只取第一个变化的 IP
        fi
    done)

    if [ -z "$IP6" ]; then
        log "未找到变化的 IP"
        sleep $CHECK_INTERVAL
        continue
    fi

    # 5. 组装 JSON（变量正确展开）
    JSON=$(cat <<EOF
{
  "name": "$SUB_DOMAIN",
  "ttl": 1,
  "type": "AAAA",
  "content": "$IP6",
  "proxied": false
}
EOF
)

    # 6. 发起更新
    RESP=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$JSON")

    # 6. 判断成功
    if echo "$RESP" | grep -q '"success":true'; then
        log "更新成功: $IP6"
    else
        log "更新失败: $(echo "$RESP" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
        sleep $CHECK_INTERVAL
        continue
    fi

    # 7. 保存当前列表作为下次比较的基准
    LAST_DDNS_IP6_LIST="$IP6_LIST"

    # 8. 等待下一轮检查
    sleep $CHECK_INTERVAL
done