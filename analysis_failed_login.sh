#!/bin/bash

OUTPUT_FILE="fail_ips.txt"
THRESHOLD=5

if [ -f /var/log/auth.log ]; then
    LOG_FILE="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
    LOG_FILE="/var/log/secure"
else
    echo "[WARN] No authentication log file found."
    exit 1
fi


> "$OUTPUT_FILE"

echo "Failed Login IP Report" | tee -a "$OUTPUT_FILE"
echo "Generated at: $(date)" | tee -a "$OUTPUT_FILE"
echo "Log file: $LOG_FILE" | tee -a "$OUTPUT_FILE"
echo "Threshold: $THRESHOLD or more failed attempts" | tee -a "$OUTPUT_FILE"
echo "==============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

FAILED_IPS=$(grep "Failed password" "$LOG_FILE" \
| awk '{for(i=1;i<=NF;i++) if ($i=="from") print $(i+1)}' \
| sort \
| uniq -c \
| awk -v threshold="$THRESHOLD" '$1 >= threshold')

if [ -z "$FAILED_IPS" ]; then
    echo "[INFO] No suspicious IPs found." | tee -a "$OUTPUT_FILE"
else
    echo "[INFO] Suspicious IPs found:" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"

    echo "$FAILED_IPS" | while read -r count ip; do
        echo "[WARN] IP: $ip / Failed Attempts: $count" | tee -a "$OUTPUT_FILE"
    done
fi

echo "" | tee -a "$OUTPUT_FILE"
echo "Analysis completed. Result saved to $OUTPUT_FILE"
