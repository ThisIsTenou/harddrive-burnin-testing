#!/bin/bash

# Check if user is root or using sudo
if [ "$USER" != root ] && [ "$SUDO_USER" != root ]; then
	echo "This script needs to be executed as root or with sudo!"
	exit 1
fi

# Define variables
fileloc="testresults/"
fileloc="${fileloc%/}"

# Find all harddrives capable of SMART-Testing
readarray -t devices < <( smartctl --scan | cut -d\# -f1 )
mkdir -p "$fileloc/"

for devicesmart in "${devices[@]}"; do
    device="$(echo $devicesmart | cut -d " " -f1)"
    if [[ $(smartctl $devicesmart -a | grep 'Rotation Rate' | grep 'rpm') ]]; then
        echo "Starting tests for $device"
        ./check-disk.sh "$device" "$fileloc" &> output.log &
    else
        echo "$device is not a HDD, skipped."
        devices=( "${devices[@]/$device}" )
    fi
done
