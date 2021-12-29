#!/bin/bash

######################################################
# To call this script, run:                          #
# ./check-disk.sh "/dev/sdX" "/path/to/resultfiles/" #
######################################################

# Check if user is root or using sudo
if [ "$USER" != root ] && [ "$SUDO_USER" != root ]; then
	echo "This script needs to be executed as root or with sudo!"
	exit 1
fi

# Check if necessary arguments have been set
if ! [[ $1 ]] || ! [[ $2 ]]; then
	echo "To call this script, run:"
    echo "./check-disk.sh \"/dev/sdX\" \"/path/to/resultfiles/\""
    exit 1
fi

# Get some variables
fileloc="${2%/}"
device="$1"
devicesmart="$(smartctl --scan | grep "${device}" | cut -d# -f1 | xargs)"
devicevis=$(echo "$1" | cut -d "/" -f3)

# Echo variables
echo ""
echo "Visual device name:                   $devicevis"
echo "Selected device:                      $device"
echo "Device-specific S.M.A.R.T. arguments: $devicesmart"
echo "Files will be stored to               ${fileloc}/"
echo ""

# Check if device is HDD
if ! [[ smartctl $devicesmart -a | grep 'Rotation Rate' | grep 'rpm' ]]; then
	echo "Selected device is not a HDD!"
    echo "Aborting."
    exit 1
fi

# Save S.M.A.R.T. data to file
echo "Writing S.M.A.R.T.-results to file..."
smartctl $device --all -H > "${fileloc}/${devicevis}-pre.txt"
echo "Done."

# Run short selftest
echo "Starting short test..."
smartctl $devicesmart -t short > /dev/null
sleep 10s
while [[ $(smartctl $device --all | grep "progress" -i -A 1) ]]; do
	echo "Waiting for test to finish..."
	sleep 30s
done
echo "Short selftest finished."

# Run conveyance selftest
echo "Starting conveyance selftest..."
smartctl $devicesmart -t conveyance > /dev/null
sleep 10s
while [[ $(smartctl $device --all | grep "progress" -i -A 1) ]]; do
	echo "Waiting for test to finish..."
	sleep 30s
done
echo "Conveyance selftest finished."

# Run long selftest
echo "Starting long selftest..."
smartctl $devicesmart -t long > /dev/null
sleep 10s
while [[ $(smartctl $device --all | grep "progress" -i -A 1) ]]; do
	echo "Waiting for test to finish..."
	sleep 30s
done
echo "Long selftest finished."

# Running badblocks on drive
echo "Running badblocks on drive..."
badblocks -ws "${device%% *}"
echo "badblocks finished."

# Run long selftest
echo "Starting long selftest..."
smartctl $devicesmart -t long > /dev/null
sleep 10s
while [[ $(smartctl $device --all | grep "progress" -i -A 1) ]]; do
	echo "Waiting for test to finish..."
	sleep 30s
done
echo "Long selftest finished."

echo "Writing S.M.A.R.T.-results to file..."
smartctl $device --all -H > "${fileloc}/${devicevis}-post.txt"
echo "All done!"
