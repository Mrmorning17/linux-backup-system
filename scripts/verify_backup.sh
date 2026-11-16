#!/bin/bash
# Verify integrity of all local backups
source "$(dirname "$(readlink -f "$0")")/lib.sh"
bad=0; n=0
for f in "$BACKUP_DIR"/backup_*.tar.gz; do
    [ -e "$f" ] || { echo "No backups found"; exit 1; }
    n=$((n+1))
    if tar -tzf "$f" >/dev/null 2>&1 && { [ ! -f "$f.sha256" ] || (cd "$BACKUP_DIR" && sha256sum -c "$(basename "$f").sha256" >/dev/null 2>&1); }; then
        echo "OK   $(basename "$f")"
    else
        echo "FAIL $(basename "$f")"; log ERROR "Integrity check failed: $f"; bad=$((bad+1))
    fi
done
echo "$n checked, $bad failed"; exit $((bad>0))
