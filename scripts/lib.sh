#!/bin/bash
# Shared helpers: logging and config loading
CONF="${BACKUP_CONF:-$(dirname "$(readlink -f "$0")")/../config/backup.conf}"
# shellcheck disable=SC1090
source "$CONF" || { echo "Cannot load config $CONF" >&2; exit 2; }

log() { # log LEVEL message
    local level="$1"; shift
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" >> "$LOG_FILE"
    [ -t 1 ] && echo "[$level] $*"
    return 0
}
die() { log ERROR "$*"; echo "ERROR: $*" >&2; exit 1; }
