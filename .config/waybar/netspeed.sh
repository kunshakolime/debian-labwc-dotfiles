#!/bin/bash
interface=$(ip -o route get 8.8.8.8 | awk '{print $5; exit}')
[ -z "$interface" ] && exit 1

cache="/tmp/waybar_netspeed"

rx=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
tx=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)
now=$(date +%s)

format() {
  if [ "$1" -gt 1048576 ]; then
    echo "$(awk "BEGIN {printf \"%.1f\", $1/1048576}")MB/s"
  elif [ "$1" -gt 1024 ]; then
    echo "$(awk "BEGIN {printf \"%.0f\", $1/1024}")KB/s"
  else
    echo "${1}B/s"
  fi
}

if [ -f "$cache" ]; then
  read old_rx old_tx old_now < "$cache"
  dt=$(( now - old_now ))
  if [ "$dt" -gt 0 ]; then
    down=$(format $(( (rx - old_rx) / dt )))
    up=$(format $(( (tx - old_tx) / dt )))
    echo " ${down}   ${up}"
  fi
fi

echo "$rx $tx $now" > "$cache"
