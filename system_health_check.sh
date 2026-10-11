#!/usr/bin/env bash
#
# ==============================================================================
# Script Name   : system_health_check.sh
# Description   : Automated Linux host health monitor, threshold alerting,
#                 and audit logging for production environments.
# Author        : Infrastructure Engineering Team
# Version       : 1.2.0
# ==============================================================================

set -euo pipefail

# ----------------- Configuration & Thresholds -----------------
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=80
LOG_FILE="/var/log/sys_monitor_$(date +'%Y%m%d').log"

# Fallback to local directory if no root write permission
if [ ! -w "/var/log" ]; then
    LOG_FILE="./sys_monitor_$(date +'%Y%m%d').log"
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

log_message() {
    local level="$1"
    local message="$2"
    echo -e "[${TIMESTAMP}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

echo "=========================================================="
echo " Starting System Audit: $(hostname) (${TIMESTAMP})"
echo "=========================================================="

# ----------------- 1. CPU Utilization Check -----------------
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'.' -f1)
CPU_USAGE=$((100 - CPU_IDLE))

if [ "${CPU_USAGE}" -ge "${CPU_THRESHOLD}" ]; then
    log_message "CRITICAL" "High CPU Utilization detected: ${CPU_USAGE}% (Threshold: ${CPU_THRESHOLD}%)"
else
    log_message "INFO" "CPU Usage normal: ${CPU_USAGE}%"
fi

# ----------------- 2. Memory Utilization Check ----------------
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

if [ "${MEM_PERCENT}" -ge "${MEM_THRESHOLD}" ]; then
    log_message "WARNING" "High Memory Usage detected: ${MEM_PERCENT}% used (${MEM_USED}MB/${MEM_TOTAL}MB)"
else
    log_message "INFO" "Memory Usage healthy: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
fi

# ----------------- 3. Root Disk Partition Check ---------------
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "${DISK_USAGE}" -ge "${DISK_THRESHOLD}" ]; then
    log_message "CRITICAL" "Root filesystem disk space running low: ${DISK_USAGE}% used!"
else
    log_message "INFO" "Root Disk Usage healthy: ${DISK_USAGE}%"
fi

# ----------------- 4. Critical Service Audits -----------------
SERVICES=("sshd" "nginx" "cron")

for SVC in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "${SVC}" 2>/dev/null; then
        log_message "OK" "Service '${SVC}' is running."
    else
        log_message "WARN" "Service '${SVC}' is inactive or not installed."
    fi
done

# ----------------- 5. Failed SSH Login Inspection -------------
FAILED_SSH=$(journalctl -u ssh --since "1 hour ago" 2>/dev/null | grep -c "Failed password" || true)
if [ "${FAILED_SSH}" -gt 5 ]; then
    log_message "SECURITY" "Potential brute force: ${FAILED_SSH} failed SSH attempts in past hour."
else
    log_message "INFO" "SSH audit clear: ${FAILED_SSH} failed attempts logged."
fi

echo "=========================================================="
log_message "INFO" "System audit completed successfully. Report saved to: ${LOG_FILE}"
echo "=========================================================="
