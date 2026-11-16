# Interview Talking Points

**30-second pitch:** "I built an automated backup and administration system for Ubuntu using Bash. It creates compressed, checksummed backups on a schedule, uploads them to AWS S3, logs every run, monitors system health, and has a restore script that refuses corrupted archives. It has automated tests and CI on GitHub Actions."

## Questions you should be ready for
**Why not just copy files?** Compressed, timestamped archives give point-in-time recovery and smaller storage; checksums detect corruption.

**What if the backup fails?** Pre-flight checks abort early, errors are logged, a failed archive is deleted, and retention never runs, so old good backups remain.

**How do you know a backup is good?** `tar -tzf` test plus SHA-256, re-checked at restore, and `verify_backup.sh` for all archives.

**Cron vs systemd timers?** Cron is simple and universal. systemd timers add `Persistent=true` (runs missed jobs after downtime), journal logging and dependency control. I included both.

**tar vs rsync?** tar gives a single portable archive (good for S3). rsync with `--link-dest` gives space-efficient incremental snapshots.

**How is AWS secured?** No keys in scripts, `aws configure` or an IAM role, and a policy limited to one bucket prefix with only List/Put/Get.

**What is the 3-2-1 rule?** 3 copies, 2 media types, 1 offsite. Local archive plus S3 covers the offsite part; I would add a second local copy to complete it.

**What would you improve?** Alerts on failure, S3 versioning/Object Lock against ransomware, KMS encryption, logrotate, database dumps, Ansible provisioning.

## Demo script (2 minutes)
```bash
make test        # automated tests pass
make demo        # backup -> verify -> delete data -> restore
cat ~/backup.log # show logging
```
