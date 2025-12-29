#!/bin/bash
# Generate detailed temperature tooltip

# CPU temperatures
cpu_tctl=$(cat /sys/class/hwmon/hwmon4/temp1_input 2>/dev/null | awk '{printf "%.1f", $1/1000}')
cpu_ccd1=$(cat /sys/class/hwmon/hwmon4/temp3_input 2>/dev/null | awk '{printf "%.1f", $1/1000}')
cpu_ccd2=$(cat /sys/class/hwmon/hwmon4/temp4_input 2>/dev/null | awk '{printf "%.1f", $1/1000}')

# GPU temperatures
gpu_edge=$(cat /sys/class/hwmon/hwmon2/temp1_input 2>/dev/null | awk '{printf "%.1f", $1/1000}')
gpu_junction=$(cat /sys/class/hwmon/hwmon2/temp2_input 2>/dev/null | awk '{printf "%.1f", $1/1000}')
gpu_mem=$(cat /sys/class/hwmon/hwmon2/temp3_input 2>/dev/null | awk '{printf "%.1f", $1/1000}')

echo "CPU Tctl: ${cpu_tctl}°C | CCD1: ${cpu_ccd1}°C | CCD2: ${cpu_ccd2}°C
GPU Edge: ${gpu_edge}°C | Junction: ${gpu_junction}°C | Memory: ${gpu_mem}°C"
