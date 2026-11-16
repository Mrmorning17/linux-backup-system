#!/bin/bash
# Usage: restore.sh <backup.tar.gz | s3://bucket/key> [restore_dir]
set -uo pipefail
source "$(dirname "$(readlink -f "$0")")/lib.sh"
SRC="${1:-}"; DEST="${2:-$HOME/restore}"
[ -n "$SRC" ] || { echo "Usage: $0 <backup.tar.gz | s3://bucket/key> [restore_dir]"; exit 2; }

if [[ "$SRC" == s3://* ]]; then
    command -v aws >/dev/null || die "aws CLI required for S3 restore"
    TMP=$(mktemp -d); aws s3 cp "$SRC" "$TMP/" --only-show-errors || die "S3 download failed"
    aws s3 cp "$SRC.sha256" "$TMP/" --only-show-errors 2>/dev/null
    SRC="$TMP/$(basename "$SRC")"
fi
[ -f "$SRC" ] || die "Backup not found: $SRC"

if [ -f "$SRC.sha256" ]; then
    ( cd "$(dirname "$SRC")" && sha256sum -c "$(basename "$SRC").sha256" >/dev/null ) \
        || die "Checksum mismatch - refusing to restore"
    log INFO "Checksum verified"
fi
tar -tzf "$SRC" >/dev/null || die "Archive is corrupt"
mkdir -p "$DEST"
tar -xzf "$SRC" -C "$DEST" || die "Extraction failed"
log INFO "Restored $SRC to $DEST"
echo "Restored to $DEST"
