#!/usr/bin/env bash
# NVIDIA GPU usage + temp for waybar (json)
read -r u t m < <(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used --format=csv,noheader,nounits | tr -d ',')
printf '{"text":"%s%%","tooltip":"GPU %s%%  ·  %s°C  ·  VRAM %s MiB"}\n' "$u" "$u" "$t" "$m"
