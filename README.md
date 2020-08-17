# NextcloudBackup
> Scripts that make a backup of Nextcloud data, config and DB. You can send it throught rsync or keep it in a local folder.

# IMPORTANT
- The script **only works** if you installed Nextcloud with snap.
- You need to generate a ssh key to send the backup throught rsync.
```bash
ssh-keygen
ssh-copy-id -i /home/example/.ssh/id_rsa targetuser@192.168.1.2 # It's an example.
```

# Release.txt

## 2020/07/18 - v0.7
- Separate data and config & db backup.
    - If data is located under a custom folder, backup command does not work properly.

## 2020/08/14 - v0.6
- Creating "ideas" section.
- Removing trash comments in the code.
- Removing ssh key generator function. I need to improve it.

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

# Ideas
- [ ] General: Telegram notification.
- [ ] General: silent mode.
- [ ] General: Github Wiki.
- [ ] General: verbose mode.
- [ ] General: merge rsync and log backup.
- [ ] General: check if rsync is installed.
- [ ] General: chmod and chown to logs folder.
- [ ] General: check updates.
- [ ] Backup: move (or not) local backup folder.
- [ ] Backup: differential and/or incremental (only data).
- [ ] Backup: only db and config files.
- [ ] Backup: Compress db and config files.
- [ ] Backup: also backup no snap installations.
- [ ] Backup: custom backup name (source and target).
- [ ] Sync: allow to send the backup through (s)ftp.
- [ ] Sync: choose between key or pass.
