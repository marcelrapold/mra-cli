#!/usr/bin/env bash
# Shared panel: System info
# Wrapper around status_panel.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/../../status_panel.sh"
