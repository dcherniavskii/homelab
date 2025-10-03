#!/usr/bin/env bash
set -euo pipefail

SUDO_CMD="${SUDO_CMD:-sudo}"
MOUNTPOINT="${1:-/mnt/syncthing-ext}"

echo "Attempting to unmount $MOUNTPOINT..."
if $SUDO_CMD veracrypt --text --dismount "$MOUNTPOINT"; then
    echo "Unmount successful. Removing $MOUNTPOINT..."
    $SUDO_CMD rmdir "$MOUNTPOINT"
else
    echo "Unmount failed. $MOUNTPOINT not removed."
    exit 1
fi
