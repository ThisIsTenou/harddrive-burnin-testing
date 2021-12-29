#!/bin/bash

# Find all harddrives capable of SMART-Testing
readarray -t devices < <( smartctl --scan | cut -d\# -f1 )
mkdir -p "testresults"

for devicesmart in "${devices[@]}"; do
    device="$(echo $devicesmart | cut -d " " -f1)"
    if [[ $(smartctl $devicesmart -a | grep 'Rotation Rate' | grep 'rpm') ]]; then
        echo "Starting tests for $device"
        ./check-disk.sh "$device" "testresults/" &
    else
        echo "$device is not a HDD, skipped."
        devices=( "${devices[@]/$device}" )
    fi
done
