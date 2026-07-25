#!/usr/bin/env bash
# Application Health Checker Script

URL="https://wisecow.local"
LOG_FILE="app_health.log"

log_status() {
    local message="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Perform curl call. 
# -k ignores SSL self-signed warnings.
# -s hides progress bar.
# -o redirects output.
# -w outputs the HTTP status code.
STATUS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS_CODE" -eq 200 ]; then
    log_status "[SUCCESS] Application is UP. HTTP Status: $STATUS_CODE"
else
    log_status "[ERROR] Application is DOWN! HTTP Status: $STATUS_CODE"
fi
