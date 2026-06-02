#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: Apache-2.0
#
# Builds OpenSSL for Android (arm64-v8a, x86_64) and packages the result
# into an AAR file with Prefab support.
#
# Usage:  ./build-android.sh [OPENSSL_VERSION]
#

set -euo pipefail

OPENSSL_VERSION="${1:-${OPENSSL_VERSION:-3.5.6}}"
OPENSSL_TAG="openssl-${OPENSSL_VERSION}"
OPENSSL_URL="https://github.com/openssl/openssl/archive/refs/tags/${OPENSSL_TAG}.tar.gz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"
SRC_DIR="${BUILD_DIR}/src/openssl-${OPENSSL_TAG}"
INSTALL_DIR="${BUILD_DIR}/install"
OUTPUT_AAR="${SCRIPT_DIR}/openssl-${OPENSSL_VERSION}.aar"

NDK_VERSION="${NDK_VERSION:-29.0.14206865}"
MIN_API="${MIN_API:-28}"

if [[ -z "${ANDROID_HOME:-}" ]]; then
  for c in "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" "/usr/local/lib/android/sdk"; do
    [[ -d "$c" ]] && { ANDROID_HOME="$c"; break; }
  done
  [[ -z "${ANDROID_HOME:-}" ]] && { echo "ERROR: ANDROID_HOME not set." >&2; exit 1; }
fi
export ANDROID_HOME

if [[ -z "${ANDROID_NDK_ROOT:-}" ]]; then
  NDK_PATH="${ANDROID_HOME}/ndk/${NDK_VERSION}"
  if [[ ! -d "$NDK_PATH" ]]; then
    echo "Installing NDK ${NDK_VERSION}..."
    yes | "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "ndk;${NDK_VERSION}" --channel=0
  fi
  ANDROID_NDK_ROOT="$NDK_PATH"
fi
export ANDROID_NDK_ROOT
echo "NDK: ${ANDROID_NDK_ROOT}"

case "$(uname -s)" in
  Linux)  HOST_TAG="linux-x86_64" ;;
  Darwin) HOST_TAG="darwin-x86_64" ;;
  *) echo "Unsupported OS" >&2; exit 1 ;;
esac
export PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_TAG}/bin:${PATH}"

mkdir -p "${BUILD_DIR}/src"
if [[ ! -d "${SRC_DIR}" ]]; then
  echo "Downloading OpenSSL ${OPENSSL_VERSION}..."
  curl -fL "${OPENSSL_URL}" -o "${BUILD_DIR}/src/${OPENSSL_TAG}.tar.gz"
  tar -xzf "${BUILD_DIR}/src/${OPENSSL_TAG}.tar.gz" -C "${BUILD_DIR}/src"
  rm "${BUILD_DIR}/src/${OPENSSL_TAG}.tar.gz"
fi

for ABI in arm64-v8a x86_64; do
  echo ""
  echo "-- Building for ${ABI} --"
  case "${ABI}" in
    arm64-v8a) TARGET="android-arm64" ;;
    x86_64)    TARGET="android-x86_64" ;;
  esac

  ABI_SRC="${BUILD_DIR}/src/${OPENSSL_TAG}-${ABI}"
  [[ -d "${ABI_SRC}" ]] && rm -rf "${ABI_SRC}"
  cp -r "${SRC_DIR}" "${ABI_SRC}"

  pushd "${ABI_SRC}" >/dev/null
  ./Configure "${TARGET}" \
    -D__ANDROID_API__="${MIN_API}" \
    --prefix="${INSTALL_DIR}/${ABI}" \
    --openssldir="${INSTALL_DIR}/${ABI}/ssl" \
    no-tests no-unit-test no-fuzz-libfuzzer no-fuzz-afl \
    shared no-static
  make -j"$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"
  make install_sw
  popd >/dev/null
done

echo ""
echo "-- Packaging AAR --"

OPENSSL_VERSION="${OPENSSL_VERSION}" \
MIN_API="${MIN_API}" \
NDK_MAJOR="$(echo "${NDK_VERSION}" | cut -d. -f1)" \
INSTALL_DIR="${INSTALL_DIR}" \
OUTPUT_AAR="${OUTPUT_AAR}" \
python3 "${SCRIPT_DIR}/package-aar.py"

echo ""
echo "Done: ${OUTPUT_AAR}"
