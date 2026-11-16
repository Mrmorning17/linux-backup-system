#!/bin/bash
# Run with sudo. Creates backup group/user and secures directories.
set -e
[ "$EUID" -eq 0 ] || { echo "Run with sudo"; exit 1; }
groupadd -f backupteam
id adminuser &>/dev/null || adduser --disabled-password --gecos "" adminuser
usermod -aG backupteam,sudo adminuser
mkdir -p /home/adminuser/important-data /home/adminuser/backups /home/adminuser/restore
chown -R adminuser:backupteam /home/adminuser/important-data /home/adminuser/backups
chmod 750 /home/adminuser/important-data /home/adminuser/backups
echo "Set a password with: sudo passwd adminuser"
id adminuser
