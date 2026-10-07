#!/bin/bash
set -e

# Detect OS (linux, darwin) and convert to lowercase
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Detect architecture (x86_64, arm64)
ARCH=$(uname -m)

# Normalize common names if necessary
if [ "$OS" = "darwin" ]; then OS="macos"; fi
if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi

# If you support Windows via Git Bash/MSYS, handle the extension
EXE_EXT=""
if [[ "$OS" == *"mingw"* || "$OS" == *"msys"* ]]; then
  OS="windows"
  EXE_EXT=".exe"
fi

# Construct the exact binary name to download
BINARY_NAME="myapp-${OS}-${ARCH}${EXE_EXT}"
DOWNLOAD_URL="https://example.com{BINARY_NAME}"

echo "Downloading ${BINARY_NAME}..."
#curl -L "$DOWNLOAD_URL" -o "myapp${EXE_EXT}"
chmod +x "myapp${EXE_EXT}"
