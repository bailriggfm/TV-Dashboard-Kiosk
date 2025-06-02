#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Replace line
echo "🔧 Patching Cage Service..."
sed -i "s|^ExecStart=.*|$CAGEEXECSTART_LINE|" "$CAGE_SERVICE_PATH"
sed -i "s/^User=<user>/User=$USERNAME/" "$CAGE_SERVICE_PATH"


cat <<EOF > $RPIGEN_CONFIG
This is a multiline string.
You can add as many lines as you want.
Each line will be written to the file.
EOF

cd "$BASE_DIR/RPI/pi-gen"
./build-docker.sh