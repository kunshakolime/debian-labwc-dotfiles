#!/bin/bash
cpu=$(vmstat 1 2 | tail -1 | awk '{printf "%d", 100 - $15}')
mem=$(free | awk '/^Mem:/ {printf "%d", $3/$2 * 100}')
echo " ${cpu}%   ${mem}%"
