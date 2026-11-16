#!/bin/bash
# Installs cron job (default) or systemd timer: ./install.sh [cron|systemd]
MODE="${1:-cron}"; DIR="$(cd "$(dirname "$0")/.." && pwd)"
chmod +x "$DIR"/scripts/*.sh
if [ "$MODE" = cron ]; then
    ( crontab -l 2>/dev/null | grep -v backup.sh; echo "0 2 * * * /bin/bash $DIR/scripts/backup.sh" ) | crontab -
    echo "Cron installed: daily at 02:00"
else
    sed "s#__DIR__#$DIR#g; s#__USER__#$USER#g" "$DIR/systemd/backup.service" | sudo tee /etc/systemd/system/backup.service >/dev/null
    sudo cp "$DIR/systemd/backup.timer" /etc/systemd/system/
    sudo systemctl daemon-reload && sudo systemctl enable --now backup.timer
    systemctl list-timers backup.timer
fi
