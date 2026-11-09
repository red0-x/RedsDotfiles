#!/usr/bin/env bash
df -h / | awk 'NR==2{printf "{\"text\":\"\",\"tooltip\":\"Disk %s / %s (%s)\"}\n", $3, $2, $5}'
