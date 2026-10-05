#!/usr/bin/env bash
# Runs Vivado batch simulation on Linux / Bash.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TCL_SCRIPT="${SCRIPT_DIR}/sim.tcl"
VIVADO_DIR="${REPO_ROOT}/vivado"

if command -v vivado >/dev/null 2>&1; then
    VIVADO_BIN="vivado"
elif [ -n "${XILINX_VIVADO:-}" ] && [ -x "${XILINX_VIVADO}/bin/vivado" ]; then
    VIVADO_BIN="${XILINX_VIVADO}/bin/vivado"
elif [ -x "/opt/Xilinx/Vivado/2019.2/bin/vivado" ]; then
    VIVADO_BIN="/opt/Xilinx/Vivado/2019.2/bin/vivado"
else
    echo "ERROR: vivado executable not found in PATH." >&2
    echo "Source settings64.sh from your Vivado installation first." >&2
    exit 1
fi

mkdir -p "$VIVADO_DIR"

# Run inside vivado/ so temporary files like .Xil stay isolated from source trees.
(
    cd "$VIVADO_DIR"
    if [ $# -gt 0 ]; then
        "$VIVADO_BIN" -mode batch -source "$TCL_SCRIPT" -nolog -nojournal -tclargs "$@"
    else
        "$VIVADO_BIN" -mode batch -source "$TCL_SCRIPT" -nolog -nojournal
    fi
)
