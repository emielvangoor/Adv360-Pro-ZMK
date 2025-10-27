#!/usr/bin/env bash

set -eu

TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")

if command -v podman &>/dev/null; then
	DOCKER="podman"
elif command -v docker &>/dev/null; then
	DOCKER="docker"
else
	echo "Error: Neither podman nor docker found in PATH"
	exit 1
fi

SELINUX_FLAGS=""
if [[ "$(uname)" != "Darwin" ]]; then
	SELINUX_FLAGS="z"
fi

echo "Building ZMK firmware with timestamp: $TIMESTAMP"
echo "Using container runtime: $DOCKER"

$DOCKER build --tag zmk --file Dockerfile .

VOLUME_FLAGS="-v $(pwd)/firmware:/app/firmware"
if [ -n "$SELINUX_FLAGS" ]; then
	VOLUME_FLAGS="$VOLUME_FLAGS:$SELINUX_FLAGS"
fi

VOLUME_FLAGS="$VOLUME_FLAGS -v $(pwd)/config:/app/config:ro"
if [ -n "$SELINUX_FLAGS" ]; then
	VOLUME_FLAGS="$VOLUME_FLAGS,$SELINUX_FLAGS"
fi

$DOCKER run --rm --name zmk \
	$VOLUME_FLAGS \
	-e TIMESTAMP=$TIMESTAMP \
	zmk

echo "Build complete! Firmware files are in ./firmware/"
echo "Left keyboard:  firmware/${TIMESTAMP}-left.uf2"
echo "Right keyboard: firmware/${TIMESTAMP}-right.uf2"

echo ""
gum confirm "Attach left side to USB-C"
cp "firmware/${TIMESTAMP}-xxxxxx-left.uf2" /Volumes/ADV360PRO/ 2>/dev/null || true
echo "Left keyboard flashed!"

gum confirm "Attach right side to USB-C"
cp "firmware/${TIMESTAMP}-xxxxxx-right.uf2" /Volumes/ADV360PRO/ 2>/dev/null || true
echo "Right keyboard flashed!"

echo "Flashing complete!"
