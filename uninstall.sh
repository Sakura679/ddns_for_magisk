#!/system/bin/sh

rm_data() {
  if [ -f "/data/adb/service.d/ddns_service.sh" ]; then
    rm -rf "/data/adb/service.d/ddns_service.sh"
  fi

}

rm_data