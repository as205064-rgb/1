#!/bin/bash

OUTPUT_FILE="hardening_result.txt"

> "$OUTPUT_FILE"

log_result() {
    local message="$1"
    echo "$message" | tee -a "$OUTPUT_FILE"
}

log_result "Linux Basic Hardening Report"
log_result "Generated at: $(date)"
log_result "=================================="
log_result ""


if ! command -v ufw >/dev/null 2>&1; then
    log_result "[WARN] UFW is not installed."
    log_result "[INFO] Install it first with: sudo apt install ufw"
    exit 1
fi


log_result "[INFO] Applying default firewall policies..."
sudo ufw default deny incoming
sudo ufw default allow outgoing


log_result "[INFO] Allowing OpenSSH..."
sudo ufw allow OpenSSH


log_result "[INFO] Enabling UFW..."
sudo ufw --force enable


log_result ""
log_result "[INFO] Final firewall status:"
ufw status verbose | tee -a "$OUTPUT_FILE"

log_result ""
log_result "Hardening completed. Result saved to $OUTPUT_FILE"
