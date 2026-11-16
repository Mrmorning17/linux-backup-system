# Linux System Administration and Automated Backup System

![CI](https://github.com/Mrmorning17/linux-backup-system/actions/workflows/ci.yml/badge.svg)
![Shell](https://img.shields.io/badge/Bash-5.x-green) ![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2F24.04-orange) ![License](https://img.shields.io/badge/license-MIT-blue)

Automates Ubuntu server administration and data protection using Bash: compressed and checksummed backups (`tar`/`gzip`), `rsync` snapshots, cron or systemd scheduling, optional AWS S3 offsite copies, logging, safe retention, system monitoring and verified restores.

## Problem
Manual administration leads to missed backups, human error, and total data loss when backups live only on the failing server. This project automates routine tasks, stores a copy off-server, and proves backups can be restored.

## Features
- Timestamped `tar.gz` backups with SHA-256 checksums and integrity testing
- Pre-flight checks (source exists, free disk space) and lock to prevent overlapping runs
- Optional AWS S3 upload and optional GPG encryption
- Retention that only runs after a successful backup and always keeps the newest 3
- Restore from local or S3 that refuses corrupted or tampered archives
- `rsync` incremental snapshots using hard links
- System monitoring (CPU, memory, disk, processes, services) with disk-usage warning
- User/group/permission setup script; cron and systemd timer installers
- Automated tests and GitHub Actions CI (ShellCheck + tests)

## Architecture
See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the diagram and design decisions.

## Tech stack
Ubuntu Linux, Bash, tar, gzip, rsync, cron, systemd, SSH, AWS S3 and AWS CLI, GPG, Git/GitHub Actions, VirtualBox or WSL.

## Project structure
```
.github/workflows/ci.yml   CI: lint + tests
config/                    backup.conf, S3 IAM policy, S3 lifecycle rule
scripts/                   backup, restore, verify_backup, rsync_backup, monitor,
                           setup_users, install, lib
systemd/                   backup.service, backup.timer
tests/run_tests.sh         sandboxed automated tests
demo/demo.sh               backup -> disaster -> restore demo
docs/                      ARCHITECTURE, PROJECT_REPORT, INTERVIEW_NOTES
```

## Getting started
```bash
sudo apt update && sudo apt install -y git rsync awscli
git clone https://github.com/Mrmorning17/linux-backup-system.git
cd linux-backup-system

make test                        # run automated tests
make demo                        # safe end-to-end demo

sudo bash scripts/setup_users.sh # create adminuser, backupteam, secure dirs
nano config/backup.conf          # set SOURCE_DIRS, S3_BUCKET, ...
make backup                      # first backup
make verify                      # integrity check
bash scripts/install.sh cron     # or: bash scripts/install.sh systemd
```

## Restore
```bash
bash scripts/restore.sh ~/backups/backup_<timestamp>.tar.gz ~/restore
bash scripts/restore.sh s3://your-bucket-name/backups/backup_<timestamp>.tar.gz ~/restore
```
Files are restored under the destination using their original path (for example `~/restore/home/adminuser/important-data/`).

## Enabling AWS S3
1. Create a bucket and an IAM user or role using [config/s3-iam-policy.json](config/s3-iam-policy.json) (replace the bucket name).
2. Run `aws configure` or attach an IAM role. Never commit keys.
3. Set `S3_BUCKET="your-bucket-name"` in `config/backup.conf`.
4. Optional lifecycle: `aws s3api put-bucket-lifecycle-configuration --bucket your-bucket-name --lifecycle-configuration file://config/s3-lifecycle.json`

## Security
Least-privilege permissions (`750`/`640`), sudo for admin tasks, no credentials in code, scoped IAM policy, optional GPG encryption, `.gitignore` blocks keys, logs and archives.

## Testing
`make test` runs sandboxed checks for backup, checksum, verification, restore, corruption detection, failure handling, logging and monitoring. Full test matrix in [docs/PROJECT_REPORT.md](docs/PROJECT_REPORT.md).

## Documentation
[Architecture](docs/ARCHITECTURE.md) | [Project report](docs/PROJECT_REPORT.md) | [Interview notes](docs/INTERVIEW_NOTES.md)

## Author
Your Name - [LinkedIn](https://linkedin.com/in/your-profile) - [GitHub](https://github.com/Mrmorning17)
