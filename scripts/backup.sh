#!/bin/bash
# Automated backup: tar+gzip, verify, checksum, optional S3 upload, safe retention
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib.sh"

exec 9>/tmp/backup.lock
flock -n 9 || die "Another backup is already running"

TS=$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p "$BACKUP_DIR"; chmod 750 "$BACKUP_DIR"
FILE="$BACKUP_DIR/backup_$TS.tar.gz"

# --- Pre-flight checks ---
for d in "${SOURCE_DIRS[@]}"; do
    [ -d "$d" ] || die "Source directory missing: $d"
done
FREE_MB=$(df -Pm "$BACKUP_DIR" | awk 'NR==2{print $4}')
[ "$FREE_MB" -ge "$MIN_FREE_MB" ] || die "Low disk space: ${FREE_MB}MB free, need ${MIN_FREE_MB}MB"

# --- Create archive (paths stored relative to /) ---
log INFO "Starting backup of: ${SOURCE_DIRS[*]}"
tar -czf "$FILE" -C / "${SOURCE_DIRS[@]#/}" 2>/tmp/backup_tar.err \
    || { rm -f "$FILE"; die "Archive creation failed: $(head -1 /tmp/backup_tar.err)"; }

# --- Verify + checksum ---
tar -tzf "$FILE" >/dev/null 2>&1 || { rm -f "$FILE"; die "Archive verification failed"; }
( cd "$BACKUP_DIR" && sha256sum "$(basename "$FILE")" > "$(basename "$FILE").sha256" )
chmod 640 "$FILE" "$FILE.sha256"
log INFO "Backup OK: $FILE ($(du -h "$FILE" | cut -f1))"

# --- Optional encryption ---
UPLOAD="$FILE"
if [ -n "$GPG_RECIPIENT" ]; then
    if gpg --batch --yes -r "$GPG_RECIPIENT" -o "$FILE.gpg" -e "$FILE"; then
        UPLOAD="$FILE.gpg"; log INFO "Encrypted: $UPLOAD"
    else
        log WARN "Encryption failed; continuing unencrypted"
    fi
fi

# --- Optional S3 upload ---
if [ -n "$S3_BUCKET" ]; then
    if command -v aws >/dev/null; then
        if aws s3 cp "$UPLOAD" "s3://$S3_BUCKET/$S3_PREFIX" --only-show-errors \
           && aws s3 cp "$FILE.sha256" "s3://$S3_BUCKET/$S3_PREFIX" --only-show-errors; then
            log INFO "Uploaded to s3://$S3_BUCKET/$S3_PREFIX"
        else
            log ERROR "S3 upload failed (local backup kept)"
        fi
    else
        log WARN "aws CLI not installed; skipping S3 upload"
    fi
fi

# --- Retention: runs only after a successful backup; always keeps newest 3 ---
ls -1t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | tail -n +4 | while read -r f; do
    if [ -n "$(find "$f" -mtime +"$RETENTION_DAYS" 2>/dev/null)" ]; then
        rm -f "$f" "$f.sha256" "$f.gpg" && log INFO "Retention: removed $(basename "$f")"
    fi
done
log INFO "Backup run finished"
