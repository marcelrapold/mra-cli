#!/usr/bin/env bash
# Shared panel: Crypto Markets
# This is a thin wrapper — the full rendering is in right_panel.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/../../right_panel.sh"
