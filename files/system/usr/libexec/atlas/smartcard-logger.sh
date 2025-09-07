#!/bin/bash
set -ouex pipefail
# Usage: smartcard-logger.sh add|remove VENDOR MODEL PRODUCT
action="${1:-}"
vendor="${2:-unknown}"
model="${3:-unknown}"
product="${4:-}"
logger -t smartcard "reader ${action}: ${vendor} ${model} ${product}"
