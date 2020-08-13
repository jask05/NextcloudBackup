# NextcloudBackup
> Scripts that make a backup of Nextcloud data, config and DB. You can send it throught rsync.

**IMPORTANT**: only backup if you installed it with snap.

# Release.txt

## 2020/08/13 - v0.5
- Adding getops
    - Local or remote backup.
    - Some help commands.
- Changed name of the main script.

## 2020/08/12 - v0.4
- Copy backup to another location using rsync.
    - Only with a public key (no password).
- Separate functions in different files: functions/main.sh and functions/nextcloud.sh
- Store logs in a log folder. Custom var.
- Delete local backup folder if you choose send the backup to a remote machine.

## 2020/08/11 - v0.3
- Change banner to a internal var.
- Modify the way to do the backup. First is a full backup (data, config and db).
    - Move the backup to a specific folder without compress it.
- Add a lot of functions
    - Maintenancemode: is only one function with two options.
- Merge release.txt into README.md

## 2020/08/05 - v0.2
- Backup of config and db files.

## 2020/08/05 - v0.1
- Starting script.
- Adding external banner.


