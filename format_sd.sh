#!/bin/bash

set -e

echo "=== SD Card Formatter ==="

# If device passed as argument, use it; otherwise prompt
DEV=$1

if [ -z "$DEV" ]; then
    echo "Available devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    echo ""
    read -p "Enter device to format (e.g., /dev/sdb or /dev/mmcblk0): " DEV
fi

# Validate block device
if [ ! -b "$DEV" ]; then
    echo "Error: $DEV is not a valid block device."
    exit 1
fi

echo ""
echo "You are about to ERASE ALL DATA on $DEV"
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Unmounting partitions..."
sudo umount ${DEV}?* 2>/dev/null || true

echo "Wiping filesystem signatures..."
sudo wipefs -a $DEV

echo "Creating new partition table..."
sudo parted -s $DEV mklabel msdos

echo "Creating primary partition..."
sudo parted -s $DEV mkpart primary fat32 1MiB 100%

# Handle partition naming
if [[ "$DEV" == *"mmcblk"* ]]; then
    PART="${DEV}p1"
else
    PART="${DEV}1"
fi

echo "Formatting as FAT32..."
sudo mkfs.vfat -F 32 $PART

echo ""
echo "Done! SD card formatted successfully:"
lsblk $DEV