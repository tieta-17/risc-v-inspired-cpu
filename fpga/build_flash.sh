#!/bin/bash
# build_flash.sh — synthesize, place & route, pack, and flash a design
# to the Tang Nano 9K, using the YoWASP toolchain + openFPGALoader.
#
# Usage:
#   ./build_flash.sh top.v top.cst
#
# Assumes:
#   - your fpga-venv is already activated (or these tools are on PATH)
#   - module name inside the .v file matches "top" (change TOP_MODULE below if not)

set -e   # stop immediately if any step fails, rather than continuing on a broken build

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <design.v> <constraints.cst>"
    exit 1
fi

SRC_V="$1"
CST="$2"
TOP_MODULE="top"
DEVICE="GW1NR-LV9QN88PC6/I5"
FAMILY="GW1N-9C"
BOARD="tangnano9k"

BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

echo "==> [1/4] Synthesis (yosys)"
yowasp-yosys -p "read_verilog ../src/*.v ${SRC_V}; synth_gowin -top ${TOP_MODULE} -json ${BUILD_DIR}/${TOP_MODULE}.json"

echo "==> [2/4] Place & route (nextpnr)"
yowasp-nextpnr-himbaechel-gowin \
    --json "${BUILD_DIR}/${TOP_MODULE}.json" \
    --write "${BUILD_DIR}/${TOP_MODULE}_pnr.json" \
    --device "${DEVICE}" \
    --vopt family="${FAMILY}" \
    --vopt cst="${CST}"

echo "==> [3/4] Pack bitstream (gowin_pack)"
gowin_pack -d "${FAMILY}" -o "${BUILD_DIR}/${TOP_MODULE}.fs" "${BUILD_DIR}/${TOP_MODULE}_pnr.json"

echo "==> [4/4] Flash to board (openFPGALoader)"
openFPGALoader -b "${BOARD}" "${BUILD_DIR}/${TOP_MODULE}.fs"

echo "==> Done. Flashed ${BUILD_DIR}/${TOP_MODULE}.fs to the Tang Nano 9K."
