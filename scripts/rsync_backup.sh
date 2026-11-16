#!/bin/bash
# Incremental snapshots using rsync with hard links to the previous snapshot
source "$(dirname "$(readlink -f "$0")")/lib.sh"
SNAP_ROOT="${BACKUP_DIR}/rsync"; mkdir -p "$SNAP_ROOT"
NEW="$SNAP_ROOT/$(date +%F_%H-%M-%S)"; LAST=$(ls -1d "$SNAP_ROOT"/20* 2>/dev/null | tail -1)
mkdir -p "$NEW"
OPTS=(-a --delete)
[ -n "$LAST" ] && OPTS+=("--link-dest=$LAST")
for d in "${SOURCE_DIRS[@]}"; do
    rsync "${OPTS[@]}" "$d" "$NEW/" || die "rsync failed for $d"
done
log INFO "rsync snapshot created: $NEW"
