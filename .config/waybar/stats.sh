#!/bin/bash
cpu() {
    awk '/^cpu / { for (i=2; i<=11; i++) t+=$i; print t, $5 }' /proc/stat
}
set -- $(cpu); prev_total=$1; prev_idle=$2
sleep 0.2
set -- $(cpu); total=$1; idle=$2
cpu=$(( 100 * ( (total - prev_total) - (idle - prev_idle) ) / (total - prev_total) ))
mem=$(free | awk '/^Mem:/ {printf "%d", $3/$2 * 100}')
echo " ${cpu}%   ${mem}%"
