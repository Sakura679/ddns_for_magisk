
#!/system/bin/sh

SKIPUNZIP=1
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

if [ "$BOOTMODE" != true ]; then
  abort "-----------------------------------------------------------"
  ui_print "! 请在 Magisk/KernelSU/APatch Manager 中安装本模块"
  ui_print "! 不支持从 Recovery 安装"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "-----------------------------------------------------------"
  ui_print "! 请升级您的 KernelSU 及其管理器"
  abort "-----------------------------------------------------------"
fi

service_dir="/data/adb/service.d"
if [ "$KSU" = "true" ]; then
  ui_print "- 检测到 KernelSU 版本: $KSU_VER ($KSU_VER_CODE)"
  [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
elif [ "$APATCH" = "true" ]; then
  APATCH_VER=$(cat "/data/adb/ap/version")
  ui_print "- 检测到 APatch 版本: $APATCH_VER"
else
  ui_print "- 检测到 Magisk 版本: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

mkdir -p "${service_dir}"
if [ -d "/data/adb/modules/ipv6-ddns" ]; then
  rm -rf "/data/adb/modules/ipv6-ddns"
  ui_print "- 已删除旧模块。"
fi

ui_print "- 正在安装 IPv6 DDNS (Cloudflare) for Magisk/KernelSU/APatch"
unzip -o "$ZIPFILE" -d "$MODPATH" >&2

ui_print "- 创建目录"

ui_print "- 提取 uninstall.sh 和 ddns_service.sh"
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'ddns_service.sh' -d "${service_dir}" >&2

ui_print "- 设置权限"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm ${service_dir}/ddns_service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
chmod ugo+x ${service_dir}/ddns_service.sh $MODPATH/uninstall.sh

ui_print " "
ui_print "==========================================================="
ui_print "==   IPv6 DDNS (Cloudflare) for Magisk/KernelSU/APatch 安装程序   =="
ui_print "==========================================================="


if [ "$KSU" = "true" ]; then
  sed -i "s/name=.*/name=IPv6 DDNS (Cloudflare) for KernelSU/g" $MODPATH/module.prop
elif [ "$APATCH" = "true" ]; then
  sed -i "s/name=.*/name=IPv6 DDNS (Cloudflare) for APatch/g" $MODPATH/module.prop
else
  sed -i "s/name=.*/name=IPv6 DDNS (Cloudflare) for Magisk/g" $MODPATH/module.prop
fi

ui_print "- 清理残留文件"
rm -rf $MODPATH/ddns_service.sh

ui_print "- 安装完成，请重启设备。"