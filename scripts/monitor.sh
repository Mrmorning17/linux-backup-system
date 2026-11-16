#!/bin/bash
# System monitoring: CPU, memory, disk, processes, uptime, services
OUT_DIR="${MONITOR_DIR:-$HOME/monitor-logs}"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/monitor_$(date +%F).log"
{
  echo "===== $(date '+%F %T') ====="
  echo "--- Uptime ---";  uptime
  echo "--- CPU / top processes ---"; top -b -n 1 | head -15
  echo "--- Memory ---";  free -h
  echo "--- Disk ---";    df -h
  echo "--- Top 5 by memory ---"; ps aux --sort=-%mem | head -6
  echo "--- Running services ---"
  systemctl --type=service --state=running --no-pager 2>/dev/null | head -20 || echo "systemctl unavailable"
  DISK=$(df / | awk 'NR==2{gsub("%","",$5);print $5}')
  [ "$DISK" -ge 85 ] && echo "WARNING: root disk usage at ${DISK}%"
  echo
} >> "$OUT"
echo "Monitoring snapshot written to $OUT"
