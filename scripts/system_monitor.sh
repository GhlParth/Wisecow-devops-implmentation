#!/usr/bin/env bash
# System Health Monitoring Script

# Predefined thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
PROCESS_THRESHOLD=500

LOG_FILE="system_health.log"

# Function to log alerts
log_alert() {
    local message="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - [ALERT] $message" | tee -a "$LOG_FILE"
}

echo "Starting System Health Check..."

# 1. CPU Usage Check
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
# Round to integer for comparison
CPU_INT=${CPU_USAGE%.*}

if [ -n "$CPU_INT" ] && [ "$CPU_INT" -gt "$CPU_THRESHOLD" ]; then
    log_alert "High CPU usage detected: ${CPU_USAGE}% (Threshold: ${CPU_THRESHOLD}%)"
else
    echo "CPU Usage: ${CPU_USAGE}% - OK"
fi

# 2. Memory Usage Check
MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
MEM_USED=$(free -m | awk '/^Mem:/{print $3}')
MEM_USAGE=$(( MEM_USED * 100 / MEM_TOTAL ))

if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    log_alert "High Memory usage detected: ${MEM_USAGE}% (Threshold: ${MEM_THRESHOLD}%)"
else
    echo "Memory Usage: ${MEM_USAGE}% - OK"
fi

# 3. Disk Space Check (on root filesystem /)
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    log_alert "High Disk usage detected on root: ${DISK_USAGE}% (Threshold: ${DISK_THRESHOLD}%)"
else
    echo "Disk Usage: ${DISK_USAGE}% - OK"
fi

# 4. Running Processes Count Check
PROCESS_COUNT=$(ps -e | wc -l)

if [ "$PROCESS_COUNT" -gt "$PROCESS_THRESHOLD" ]; then
    log_alert "High Process count detected: ${PROCESS_COUNT} running processes (Threshold: ${PROCESS_THRESHOLD})"
else
    echo "Running Processes: ${PROCESS_COUNT} - OK"
fi

echo "System Health Check complete."
