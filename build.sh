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

# Function to display all configuration options and get user selection
select_configuration() {
  echo "Please select a configuration:"
  local i=1
  local valid_configs=()

  # Display all configurations
  for config_name in "${CONFIG_MATRIX[@]}"; do
    # Get array values properly preserving spaces
    eval "local name=\${$config_name[0]}"
    eval "local build_type=\${$config_name[1]}"
    eval "local app=\${$config_name[2]}"
    eval "local exec_cmd=\${$config_name[3]}"

    echo "$i) $name"
    valid_configs+=("$config_name")
    ((i++))
  done

  read -p "Enter the number of your choice: " CONFIG_CHOICE

  if [[ "$CONFIG_CHOICE" -lt 1 || "$CONFIG_CHOICE" -gt ${#valid_configs[@]} ]]; then
    echo "Invalid choice. Exiting."
    exit 1
  fi

  # Set the selected configuration
  selected_config="${valid_configs[$CONFIG_CHOICE-1]}"

  # Get array values properly preserving spaces
  eval "export BUILD_TYPE=\${$selected_config[1]}"
  eval "export CAGED_APP=\${$selected_config[2]}"
  eval "export CAGEEXECSTART_LINE=\${$selected_config[3]}"
  eval "local name=\${$selected_config[0]}"

  echo "Selected configuration: $name"
}

# Select configuration directly
select_configuration

# Process the build based on the selected configuration
if [[ "$BUILD_TYPE" == "x86_64" ]]; then
  echo "Building x86_64 image with $CAGED_APP..."
  cp -r "$BASE_DIR/x86_64/." "$CONFIG_DIR"
  cp -r "$BASE_DIR/airootfs-shared/." "$CONFIG_DIR/airootfs/"
  "$BASE_DIR/x86_64/build-x86_64.sh"
elif [[ "$BUILD_TYPE" == "RPI" || "$BUILD_TYPE" == "RPI32" || "$BUILD_TYPE" == "RPI64"   ]]; then
  # Extract bit architecture from the configuration name
  if [[ "${BUILD_TYPE}" == *"RPI32"* ]]; then
    RPI_ARCH="32"
  elif [[ "${BUILD_TYPE}" == *"RPI64"* ]]; then
    RPI_ARCH="64"
  else
    # If not specified in name, ask the user
    read -p "Would you like to build a 32-bit or 64-bit RPI image? (32/64): " RPI_ARCH
  fi

  case $RPI_ARCH in
    32)
      echo "Building 32-bit RPI image with $CAGED_APP..."
      cp -r "$BASE_DIR/RPI/." "$CONFIG_DIR"
      cp -r "$BASE_DIR/airootfs-shared/." "$CONFIG_DIR/airootfs/"
      "$BASE_DIR/RPI/build-RPI.sh"
      ;;
    64)
      echo "Building 64-bit RPI image with $CAGED_APP..."
      git -C "$BASE_DIR/RPI/pi-gen" checkout bookworm-arm64
      cp -r "$BASE_DIR/RPI/." "$CONFIG_DIR"
      cp -r "$BASE_DIR/airootfs-shared/." "$CONFIG_DIR/airootfs/"
      git -C "$BASE_DIR/RPI/pi-gen" checkout bookworm
      "$BASE_DIR/RPI/build-RPI.sh"
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
else
  echo "Unknown build type: $BUILD_TYPE. Exiting."
  exit 1
fi

