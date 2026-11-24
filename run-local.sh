#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR"

if command -v python3 >/dev/null 2>&1; then
  exec python3 run-local.py
elif command -v python >/dev/null 2>&1; then
  exec python run-local.py
else
  echo "Python 3 is required. Install Python 3, then run this script again."
  exit 1
fi
