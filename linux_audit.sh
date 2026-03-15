#!/bin/bash

OUTPUT_FILE="audit_result.txt"

> "$OUTPUT_FILE"

print_result() {
    local status="$1"
    local item="$2"
    local detail="$3"

    echo "[$status] $item" | tee -a "$OUTPUT_FILE"
    echo " - $detail" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
}

echo "Linux Security Audit Report" | tee -a "$OUTPUT_FILE"
echo "Generated at: $(date)" | tee -a "$OUTPUT_FILE"
echo "==================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

#SSH root login
if [ -f /etc/ssh/sshd_config ]; then
    if grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no' /etc/ssh/sshd_config; then
        print_result "PASS" "SSH root login" "PermitRootLogin is set to no"
    else
        print_result "WARN" "SSH root login" "PermitRootLogin may be enabled or not explicitly configured"
    fi
else
    print_result "WARN" "SSH root login" "/etc/ssh/sshd_config file not found"
fi

#sudo group
SUDO_USERS=$(getent group sudo | cut -d: -f4)
if [ -n "$SUDO_USERS" ]; then
    print_result "INFO" "Sudo users" "Users in sudo group: $SUDO_USERS"
else
    print_result "INFO" "Sudo users" "No users found in sudo group"
fi

#passwd
if [ -f /etc/passwd ]; then
    PASSWD_PERM=$(stat -c "%a" /etc/passwd)
    if [ "$PASSWD_PERM" = "644" ]; then
        print_result "PASS" "/etc/passwd permission" "Permission is 644"
    else
        print_result "WARN" "/etc/passwd permission" "Current permission is $PASSWD_PERM"
    fi
else
    print_result "WARN" "/etc/passwd permission" "/etc/passwd file not found"
fi

#shadow
if [ -f /etc/shadow ]; then
    SHADOW_PERM=$(stat -c "%a" /etc/shadow)
    if [ "$SHADOW_PERM" = "640" ] || [ "$SHADOW_PERM" = "600" ]; then
        print_result "PASS" "/etc/shadow permission" "Permission is $SHADOW_PERM"
    else
        print_result "WARN" "/etc/shadow permission" "Current permission is $SHADOW_PERM"
    fi
else
    print_result "WARN" "/etc/shadow permission" "/etc/shadow file not found"
fi

# firewall
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status | head -n 1)
    print_result "INFO" "Firewall status" "$UFW_STATUS"
else
    print_result "WARN" "Firewall status" "UFW is not installed"
fi

#service
if command -v systemctl >/dev/null 2>&1; then
    ENABLED_SERVICES=$(systemctl list-unit-files --type=service --state=enabled 2>/dev/null | head -n 10)
    print_result "INFO" "Enabled services" "Top enabled services:
$ENABLED_SERVICES"
else
    print_result "WARN" "Enabled services" "systemctl is not available"
fi

#login
if command -v last >/dev/null 2>&1; then
    RECENT_LOGINS=$(last -n 5 2>/dev/null)
    print_result "INFO" "Recent logins" "Last 5 login records:
$RECENT_LOGINS"
else
    print_result "WARN" "Recent logins" "'last' command is not available"
fi

echo "Audit completed. Result saved to $OUTPUT_FILE"
