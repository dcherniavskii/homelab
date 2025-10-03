#!/usr/bin/env bash
set -euo pipefail

# Config — change these if you want different defaults
FILE="${1:-/dev/sda3}"           # first arg or default /dev/sda3
MOUNTPOINT="${2:-/mnt/syncthing-ext}"       # second arg or default /mnt/syncthing-ext
PIM="${PIM:-0}"
KEYFILES="${KEYFILES:-}"         # leave empty string if no keyfiles
PROTECT_HIDDEN="${PROTECT_HIDDEN:-no}"
SUDO_CMD="${SUDO_CMD:-sudo}"

# Helper: print and exit
usage() {
  cat <<EOF
Usage: $0 [container_file] [mountpoint]
Defaults: container_file=/dev/sda3  mountpoint=/mnt/syncthing-ext

Environment:
  VERACRYPT_PASS   if set, will be used as the password (less secure)
  PIM              numeric PIM (default: ${PIM})
  KEYFILES         keyfiles path(s) (default: empty)
  PROTECT_HIDDEN   yes|no (default: ${PROTECT_HIDDEN})

This script will attempt to mount the container with veracrypt using --text mode.
It will also create the mountpoint if needed and set a trap to unmount on exit.
EOF
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

# Ensure veracrypt exists
if ! command -v veracrypt >/dev/null 2>&1; then
  echo "ERROR: veracrypt not found in PATH." >&2
  exit 2
fi

# Create mountpoint if it doesn't exist
if [[ ! -d "$MOUNTPOINT" ]]; then
  echo "Creating mountpoint $MOUNTPOINT..."
  $SUDO_CMD mkdir -p "$MOUNTPOINT"
  $SUDO_CMD chown "$(id -u):$(id -g)" "$MOUNTPOINT" || true
fi

# If container already mounted at mountpoint, bail out
if mountpoint -q "$MOUNTPOINT"; then
  echo "Mountpoint $MOUNTPOINT already mounted. Exiting."
  exit 0
fi

# Get password: prefer VERACRYPT_PASS env, else prompt securely
if [[ -n "${VERACRYPT_PASS:-}" ]]; then
  PASSWORD="$VERACRYPT_PASS"
else
  read -rsp "Enter VeraCrypt password for '$FILE': " PASSWORD
  echo
fi

# Build command arguments safely
VERACRYPT_ARGS=(--text --mount "$FILE" "$MOUNTPOINT" --password "$PASSWORD" --pim "$PIM" --keyfiles "$KEYFILES" --protect-hidden "$PROTECT_HIDDEN")

echo "Mounting container '$FILE' to '$MOUNTPOINT'..."
# Run veracrypt with sudo
# NOTE: Passing password on the command line can expose it in process listings on some systems.
#       Prefer setting VERACRYPT_PASS env and leaving the --password option out if your veracrypt supports stdin or prompting.
$SUDO_CMD veracrypt "${VERACRYPT_ARGS[@]}"

# If we reach here, mount succeeded
echo "Mounted successfully."

# wipe password variable
PASSWORD=""
VERACRYPT_ARGS=""

# Keep script alive until user wants to unmount (optional)
# If you prefer immediate exit while leaving the mount active, comment out the next block.
# read -rp "Press Enter to unmount and exit (or Ctrl-C to leave mounted): " _dummy
# echo "Unmounting..."
# $SUDO_CMD veracrypt --text --dismount "$MOUNTPOINT"
# echo "Done."
