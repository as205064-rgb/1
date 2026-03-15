#!/bin/bash

REPORT_FILE="incident_report_$(date +%Y%m%d).txt"
TODAY=$(date '+%b %e')

if [ -r "/var/log/auth.log" ]; then
    LOG_FILE="/var/log/auth.log"
elif [ -r "/var/log/secure" ]; then
    LOG_FILE="/var/log/secure"
else
    echo "[ERROR] Cannot read /var/log/auth.log or /var/log/secure."
    echo "Run this script with sudo or root privileges."
    exit 1
fi

TODAY_LOG=$(mktemp)
grep "^$TODAY" "$LOG_FILE" > "$TODAY_LOG"

print_header() {
    {
        echo "=========================================="
        echo " Daily Security Incident & Log Report "
        echo " Generated at: $(date)"
        echo " Log source   : $LOG_FILE"
        echo " Date filter  : $TODAY"
        echo "=========================================="
        echo
    } > "$REPORT_FILE"
}

print_section() {
    {
        echo "[$1] $2"
        echo "------------------------------------------"
    } >> "$REPORT_FILE"
}

print_no_result() {
    echo "No relevant events found." >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
}

print_header

print_section "1" "Top 5 Suspicious IPs (Failed SSH Logins)"
FAILED_IPS=$(grep "Failed password" "$TODAY_LOG" | grep -oE 'from ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | sort | uniq -c | sort -nr | head -n 5)

if [ -n "$FAILED_IPS" ]; then
    echo "$FAILED_IPS" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    print_no_result
fi

print_section "2" "Top 5 Targeted Accounts (Failed SSH Logins)"
FAILED_USERS=$(grep "Failed password" "$TODAY_LOG" | sed -n 's/.*Failed password for \(invalid user \)\?\([^ ]*\) from.*/\2/p' | sort | uniq -c | sort -nr | head -n 5)

if [ -n "$FAILED_USERS" ]; then
    echo "$FAILED_USERS" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    print_no_result
fi

print_section "3" "Successful SSH Logins"
SUCCESS_LOGINS=$(grep -E "Accepted (password|publickey|keyboard-interactive/pam)" "$TODAY_LOG" | \
awk '{
    for(i=1;i<=NF;i++) {
        if($i=="for") user=$(i+1);
        if($i=="from") ip=$(i+1);
    }
    print "User:", user, "| IP:", ip, "| Time:", $1, $2, $3
}')

if [ -n "$SUCCESS_LOGINS" ]; then
    echo "$SUCCESS_LOGINS" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    print_no_result
fi

print_section "4" "New User Account Creations"
NEW_USERS=$(grep -Ei "new user|useradd|adduser" "$TODAY_LOG")

if [ -n "$NEW_USERS" ]; then
    echo "$NEW_USERS" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    print_no_result
fi

print_section "5" "Privilege Escalation Attempts (sudo usage)"
SUDO_LOGS=$(grep -i "sudo:" "$TODAY_LOG")

if [ -n "$SUDO_LOGS" ]; then
    echo "$SUDO_LOGS" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    print_no_result
fi

print_section "6" "User Switching Events (su)"
SU_LOGS=$(grep -E "su:|session opened for user root by" "$TODAY_LOG")

if [ -n "$SU_LOGS" ]; then
    echo "$SU_LOGS" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    print_no_result
fi

print_section "7" "Direct Root Login Check"
ROOT_LOGIN=$(grep -E "Accepted (password|publickey|keyboard-interactive/pam) for root" "$TODAY_LOG")

if [ -n "$ROOT_LOGIN" ]; then
    echo "[WARNING] Direct root login detected:" >> "$REPORT_FILE"
    echo "$ROOT_LOGIN" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
else
    echo "No direct root login detected." >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
fi

print_section "8" "Summary"
FAILED_COUNT=$(grep -c "Failed password" "$TODAY_LOG")
SUCCESS_COUNT=$(grep -Ec "Accepted (password|publickey|keyboard-interactive/pam)" "$TODAY_LOG")
NEW_USER_COUNT=$(grep -Eic "new user|useradd|adduser" "$TODAY_LOG")
SUDO_COUNT=$(grep -ic "sudo:" "$TODAY_LOG")

{
    echo "Failed SSH login attempts : $FAILED_COUNT"
    echo "Successful SSH logins     : $SUCCESS_COUNT"
    echo "New user-related events   : $NEW_USER_COUNT"
    echo "sudo-related events       : $SUDO_COUNT"
    echo
} >> "$REPORT_FILE"

rm -f "$TODAY_LOG"

echo "Report generation complete. Check $REPORT_FILE"
cat "$REPORT_FILE"
