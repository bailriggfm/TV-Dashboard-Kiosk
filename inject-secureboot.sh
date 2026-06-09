#!/bin/bash
set -euo pipefail


# Check if openssl is installed
if ! command -v openssl &> /dev/null; then
  echo "OpenSSL is not installed. Please install OpenSSL." >&2
  exit 1
fi

if ! command -v osirrox &> /dev/null; then
  echo "xorriso is not installed. Please install xorriso." >&2
  exit 1
fi

if ! command -v sbsign &> /dev/null; then
  echo "sbsigntool is not installed. Please install sbsigntool." >&2
  exit 1
fi

if ! command -v rpm2cpio &> /dev/null; then
  echo "rpm2cpio is not installed. Please install rpm2cpio." >&2
  exit 1
fi

if ! command -v cpio &> /dev/null; then
  echo "cpio is not installed. Please install cpio." >&2
  exit 1
fi

if ! command -v mcopy &> /dev/null; then
  echo "mtools is not installed. Please install mtools." >&2
  exit 1
fi

usage() {
  cat <<EOF
Usage:
  $0 generate-mok <dest-dir> [days]
  $0 inject --in <input.iso> --out <output.iso> --key <MOK.key> --cer <MOK.cer> --crt <MOK.crt>
EOF
  exit 1
}

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$(pwd)/$1" ;;
  esac
}

generate_mok() {
    local dest_dir="$1"
    local days="${2:-3650}"

    dest_dir="$(resolve_path "$dest_dir")"
    mkdir -p "$dest_dir"

    local key_path="$dest_dir/MOK.key"
    local crt_path="$dest_dir/MOK.crt"
    local cer_path="$dest_dir/MOK.cer"

    openssl req \
        -newkey rsa:4096 \
        -nodes \
        -keyout "$key_path" \
        -new \
        -x509 \
        -sha256 \
        -days "$days" \
        -subj "/CN=Machine Owner Key/" \
        -out "$crt_path"

    openssl x509 \
        -outform DER \
        -in "$crt_path" \
        -out "$cer_path"

    echo "Generated:"
    echo "  $key_path"
    echo "  $crt_path (PEM)"
    echo "  $cer_path (DER)"
}

inject_secureboot() {
  SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
  SHIM_RPM="$SCRIPT_DIR/shim-x64-16.1-8.x86_64.rpm"
  INISO=""
  OUTISO=""
  MOK_KEY=""
  MOK_CER=""
  MOK_CRT=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --in) INISO="$2"; shift 2;;
      --out) OUTISO="$2"; shift 2;;
      --key) MOK_KEY="$2"; shift 2;;
      --cer) MOK_CER="$2"; shift 2;;
      --crt) MOK_CRT="$2"; shift 2;;
      --help) usage;;
      *) echo "Unknown arg: $1"; usage;;
    esac
  done

  if [ -z "$INISO" ] || [ -z "$OUTISO" ] || [ -z "$MOK_KEY" ] || [ -z "$MOK_CER" ]; then
    echo "Missing required arguments" >&2
    usage
  fi
  INISO="$(resolve_path "$INISO")"
  OUTISO="$(resolve_path "$OUTISO")"
  MOK_KEY="$(resolve_path "$MOK_KEY")"
  MOK_CER="$(resolve_path "$MOK_CER")"
  MOK_CRT="$(resolve_path "$MOK_CRT")"
  SHIM_RPM="$(resolve_path "$SHIM_RPM")"

  if [ ! -f "$INISO" ]; then
    echo "Input ISO not found: $INISO" >&2
    exit 1
  fi
  if [ ! -f "$MOK_KEY" ] || [ ! -f "$MOK_CER" ] || [ ! -f "$MOK_CRT" ]; then
    echo "MOK key or certificate not found" >&2
    exit 1
  fi

  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT
  mkdir -p "$TMPDIR/boot"

  osirrox -indev "$INISO" \
    -extract_boot_images "$TMPDIR/boot/" \
    -extract /EFI/BOOT/BOOTx64.EFI "$TMPDIR/boot/grubx64.efi" \
    -extract /arch/boot/x86_64/vmlinuz-linux "$TMPDIR/boot/vmlinuz-linux"

  chmod +w "$TMPDIR/boot/grubx64.efi" "$TMPDIR/boot/vmlinuz-linux"

  sbsign --key "$MOK_KEY" --cert "$MOK_CRT" --output "$TMPDIR/boot/grubx64.efi" "$TMPDIR/boot/grubx64.efi"
  sbsign --key "$MOK_KEY" --cert "$MOK_CRT" --output "$TMPDIR/boot/vmlinuz-linux" "$TMPDIR/boot/vmlinuz-linux"

  mkdir -p "$TMPDIR/shim-signed"
  (cd "$TMPDIR/shim-signed" && rpm2cpio "$SHIM_RPM" | cpio -idmv >/dev/null 2>&1)

  SHIM_BASE=$(find "$TMPDIR/shim-signed" -type f -name shimx64.efi -o -name mmx64.efi -o -name BOOTX64.CSV | sed -n '1p' | xargs -I{} dirname {}) || true
  if [ -z "$SHIM_BASE" ]; then
    SHIM_BASE="$TMPDIR/shim-signed"
  fi

  SHIM_SHIM=$(find "$SHIM_BASE" -type f -name shimx64.efi | head -n1)
  SHIM_MOK=$(find "$SHIM_BASE" -type f -name BOOTX64.CSV | head -n1)
  SHIM_MMX=$(find "$SHIM_BASE" -type f -name mmx64.efi | head -n1)

  cp "$SHIM_SHIM" "$TMPDIR/boot/BOOTx64.EFI"
  cp "$SHIM_MOK" "$TMPDIR/boot/BOOTX64.CSV"
  cp "$SHIM_MMX" "$TMPDIR/boot/mmx64.efi"

  cp "$MOK_CER" "$TMPDIR/boot/ENROLL-THIS-KEY-IN-MOK-MANAGER.cer"
  ELTORITO_IMG="$TMPDIR/boot/eltorito_img2_uefi.img"
  if [ ! -f "$ELTORITO_IMG" ]; then
    echo "eltorito image not found in extracted boot images" >&2
    exit 1
  fi

  mcopy -D oO -i "$ELTORITO_IMG" "$TMPDIR/boot/vmlinuz-linux" ::/arch/boot/x86_64/vmlinuz-linux
  mcopy -D oO -i "$ELTORITO_IMG" "$TMPDIR/boot/ENROLL-THIS-KEY-IN-MOK-MANAGER.cer" ::/
  mcopy -D oO -i "$ELTORITO_IMG" "$TMPDIR/boot/BOOTx64.EFI" "$TMPDIR/boot/BOOTX64.CSV" "$TMPDIR/boot/grubx64.efi" "$TMPDIR/boot/mmx64.efi" ::/EFI/BOOT/

  (cd "$TMPDIR/boot" && xorriso -indev "$INISO" \
    -outdev "$OUTISO" \
    -map vmlinuz-linux /arch/boot/x86_64/vmlinuz-linux \
    -map_l ./ / ENROLL-THIS-KEY-IN-MOK-MANAGER.cer -- \
    -map_l ./ /EFI/BOOT/ BOOTx64.EFI BOOTX64.CSV grubx64.efi mmx64.efi -- \
    -boot_image any replay \
    -append_partition 2 0xef eltorito_img2_uefi.img)
  echo "Created secure ISO: $OUTISO"
}

if [ "$#" -lt 1 ]; then
  usage
fi

case "$1" in
  generate-mok)
    if [ "$#" -lt 3 ]; then
      usage
    fi
    generate_mok "$2" "$3" "${4:-}" ;;
  inject)
    shift
    inject_secureboot "$@" ;;
  *) usage ;;
esac