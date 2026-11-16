# Project Report (continuation: Sections 8-12)

## 8. Testing and Validation

| Test case | Expected result | How to verify |
|---|---|---|
| Create a Linux user | User created successfully | `id adminuser` |
| Assign user to group | User appears in `backupteam` | `groups adminuser` |
| Apply directory permissions | Directory is `750`, owned by `adminuser:backupteam` | `ls -ld ~/important-data` |
| Unauthorized access | Non-group user gets "Permission denied" | `sudo -u otheruser ls ~/backups` |
| Run monitoring script | Snapshot with CPU, memory, disk, uptime appended to log | `bash scripts/monitor.sh` |
| Create backup | Timestamped `.tar.gz` and `.sha256` created, success logged | `bash scripts/backup.sh` |
| Verify archive | `tar -tzf` succeeds and checksum matches | `bash scripts/verify_backup.sh` |
| Missing source directory | Backup aborts, error logged, no archive | Change `SOURCE_DIRS`, rerun |
| Low disk space | Backup aborts before creating archive | Set `MIN_FREE_MB` very high |
| Cron scheduling | Backup runs automatically at 02:00 | `grep CRON /var/log/syslog` |
| systemd timer | Timer listed and triggers service | `systemctl list-timers backup.timer` |
| S3 upload | Object appears in bucket | `aws s3 ls s3://your-bucket-name/backups/` |
| Local restore | Restored files identical to source | `diff -r` source vs restore dir |
| Cloud restore | File downloaded from S3 and restored | `bash scripts/restore.sh s3://...` |
| Corrupted archive | Restore refused | Truncate a copy, run restore |
| Retention policy | Old archives removed, newest 3 always kept | Run with old-dated files |

Automated sandbox tests (`tests/run_tests.sh`) cover backup, checksum, verification, restore, corruption detection, missing source, logging and monitoring. All 9 checks passed during development.

## 9. Results

- A single command creates a verified, checksummed, timestamped backup and logs the outcome.
- Backups run unattended via cron or a systemd timer.
- Restores validate integrity first, so a damaged archive is never silently extracted.
- Offsite copies in S3 protect against loss of the whole server.
- Monitoring logs give daily visibility into CPU, memory, disk and services.

## 10. Challenges and Solutions

| Challenge | Solution |
|---|---|
| Cron has a minimal environment (PATH, HOME) | Use absolute paths; config file instead of environment variables |
| Overlapping backup runs | `flock` lock file |
| Retention could delete good backups after repeated failures | Retention runs only after success and always keeps the newest 3 |
| Credentials in scripts | AWS CLI profile or IAM role; least-privilege policy |
| Silent corruption | SHA-256 checksum plus `tar -tzf` test, checked again at restore |
| Disk filling up | Free-space pre-check and retention |

## 11. Future Enhancements

- Email or Slack alerts on backup failure.
- Weekly full plus daily incremental strategy using `rsync` snapshots.
- Server-side encryption (SSE-KMS) and S3 versioning / Object Lock against ransomware.
- Centralized monitoring (Prometheus + Grafana) and log rotation with `logrotate`.
- Backing up databases (`mysqldump`/`pg_dump`) before archiving.
- Ansible playbook to provision the whole server.
- Scheduled automatic restore drills.

## 12. Conclusion

The project replaces repetitive manual administration with tested Bash automation. Backups are scheduled, verified, logged and stored both locally and in AWS S3, and restoration has been proven to work, so data can be recovered after deletion, corruption or server failure. The result is a more reliable, secure and low-maintenance Linux environment.
