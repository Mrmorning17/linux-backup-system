#!/bin/bash
# End-to-end demo in a throwaway folder (safe to run anywhere, no sudo needed).
# Shows: backup -> verify -> delete data -> restore -> compare.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D=$(mktemp -d); mkdir -p "$D/important-data"
echo "Quarterly report" > "$D/important-data/report.txt"
echo "Customer list"    > "$D/important-data/customers.csv"
cat > "$D/demo.conf" <<CONF
SOURCE_DIRS=("$D/important-data")
BACKUP_DIR="$D/backups"
LOG_FILE="$D/backup.log"
RETENTION_DAYS=7
MIN_FREE_MB=1
S3_BUCKET=""
S3_PREFIX="backups/"
GPG_RECIPIENT=""
CONF
export BACKUP_CONF="$D/demo.conf"
echo "== 1. Creating backup ==";        bash "$ROOT/scripts/backup.sh" >/dev/null; ls "$D/backups"
echo "== 2. Verifying integrity ==";    bash "$ROOT/scripts/verify_backup.sh"
echo "== 3. Simulating disaster: deleting data =="; rm -rf "$D/important-data"; ls "$D"
echo "== 4. Restoring ==";              bash "$ROOT/scripts/restore.sh" "$(ls "$D"/backups/*.tar.gz)" "$D/restored" >/dev/null
echo "== 5. Recovered files ==";        find "$D/restored" -type f
echo "== 6. Log ==";                    cat "$D/backup.log"
rm -rf "$D"
