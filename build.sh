#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Please install Docker." >&2
  exit 1
fi

# Check if Docker service is running
if ! systemctl is-active --quiet docker; then
  read -p "Docker service is not running. Would you like to start it? (y/n): " START_DOCKER
  if [[ "$START_DOCKER" =~ ^[Yy]$ ]]; then
    sudo systemctl start docker
    if ! systemctl is-active --quiet docker; then
      echo "Failed to start Docker service. Please check your system configuration." >&2
      exit 1
    fi
  else
    echo "Docker service is required to proceed. Exiting." >&2
    exit 1
  fi
fi

# Change to the directory of the script
export BASE_DIR="$(realpath "$(dirname "$0")")"
cd "$BASE_DIR"

source "$BASE_DIR/config.sh"

# Prompt the user to select the build type
echo "Which image would you like to build?"
echo "1) x86_64"
echo "2) RPI"
read -p "Enter the number of your choice: " BUILD_CHOICE

case $BUILD_CHOICE in
  1)
    echo "Building x86_64 image..."
    cp -r "$BASE_DIR/x86_64/." "$CONFIG_DIR"
    cp -r "$BASE_DIR/airootfs-shared/." "$CONFIG_DIR/airootfs/"
    "$BASE_DIR/x86_64/build-x86_64.sh"
    ;;
  2)
    echo "Building RPI image..."
    read -p "Would you like to build a 32-bit or 64-bit RPI image? (32/64): " RPI_ARCH
    case $RPI_ARCH in
      32)
        echo "Building 32-bit RPI image..."
        cp -r "$BASE_DIR/RPI/." "$CONFIG_DIR"
        cp -r "$BASE_DIR/airootfs-shared/." "$CONFIG_DIR/airootfs/"
        "$BASE_DIR/RPI/build-RPI.sh"
        ;;
      64)
        echo "Building 64-bit RPI image..."
        git -C "$BASE_DIR/RPI/pi-gen" checkout arm64
        cp -r "$BASE_DIR/RPI/." "$CONFIG_DIR"
        cp -r "$BASE_DIR/airootfs-shared/." "$CONFIG_DIR/airootfs/"
        git -C "$BASE_DIR/RPI/pi-gen" checkout master
        "$BASE_DIR/RPI/build-RPI.sh"
        ;;
      *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

