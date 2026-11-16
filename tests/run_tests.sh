#!/bin/bash
# Self-contained test: uses a temp sandbox, never touches real data
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; T=$(mktemp -d)
mkdir -p "$T/src/sub"; echo "hello" > "$T/src/a.txt"; echo "world" > "$T/src/sub/b.txt"
cat > "$T/test.conf" <<CONF
SOURCE_DIRS=("$T/src")
BACKUP_DIR="$T/backups"
LOG_FILE="$T/backup.log"
RETENTION_DAYS=7
MIN_FREE_MB=1
S3_BUCKET=""
S3_PREFIX="backups/"
GPG_RECIPIENT=""
CONF
export BACKUP_CONF="$T/test.conf" HOME="$T"
pass=0; fail=0
check() { if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

bash "$ROOT/scripts/backup.sh" >/dev/null
check "backup archive created"        "ls $T/backups/backup_*.tar.gz >/dev/null 2>&1"
check "checksum file created"         "ls $T/backups/backup_*.sha256 >/dev/null 2>&1"
check "log records success"           "grep -q 'Backup OK' $T/backup.log"
check "verify_backup passes"          "bash $ROOT/scripts/verify_backup.sh >/dev/null"
F=$(ls $T/backups/backup_*.tar.gz | head -1)
bash "$ROOT/scripts/restore.sh" "$F" "$T/restored" >/dev/null
check "restore reproduces files"      "diff -r $T/src $T/restored$T/src"
# corruption detection
cp "$F" "$T/bad.tar.gz"; echo "junk" >> "$T/bad.tar.gz"; head -c 100 "$F" > "$T/bad.tar.gz"
check "corrupt archive rejected"      "! bash $ROOT/scripts/restore.sh $T/bad.tar.gz $T/x >/dev/null 2>&1"
# missing source
sed -i "s#$T/src#$T/nope#" "$T/test.conf"
check "missing source detected"       "! bash $ROOT/scripts/backup.sh >/dev/null 2>&1"
check "failure logged"                "grep -q 'Source directory missing' $T/backup.log"
# monitoring
check "monitor script runs"           "MONITOR_DIR=$T/mon bash $ROOT/scripts/monitor.sh >/dev/null 2>&1 && ls $T/mon/*.log >/dev/null"
echo "Passed: $pass  Failed: $fail"; rm -rf "$T"; [ $fail -eq 0 ]
