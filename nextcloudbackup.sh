#!/usr/bin/env bash
# Make Nextcloud Backup: DB, config folder and data

# Main config. NOT TOUCH !!!
TIMESTAMP=$(date +"%Y-%m-%d %T")
CLEANTIMESTAMP=$(date +"%Y%m%d-%H%M%S")
SCRIPTDIR=$(dirname "$0")
VERSION="0.7"

# RSYNC parameters
IDRSA="/home/${SUDO_USER}/.ssh/id_rsa"
REMOTEUSER="testrsync"
REMOTEHOST="127.0.0.1"
REMOTESTORAGEFOLDER="/home/testrsync/"

# Custom config
LOGFOLDER="${SCRIPTDIR}/logs"
BACKUPSTORAGEFOLDER="/home/${SUDO_USER}/nextcloudbackup"
PREFIXBACKUPLOG="nextcloudbackup"
SUFIXBACKUPLOG="${CLEANTIMESTAMP}.log"
BACKUPLOG="${PREFIXBACKUPLOG}_${SUFIXBACKUPLOG}"
RSYNCLOG="rsync.log"

# Functions
. "${SCRIPTDIR}/functions/main.sh"
. "${SCRIPTDIR}/functions/nextcloud.sh"

# Wellcome banner
WELLCOMEBANNER

# Script options
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
# options=$(getopt -l "help,version:,verbose,rebuild,dryrun" -o "hv:Vrd" -a -- "$@")
options=$(getopt --long "help,version,backup-mode:" -o "hvb:" -a -- "$@")

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters 
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
case $1 in
-b|--backup-mode)
    BACKUPTYPE=$2
    if [ "$BACKUPTYPE" = "local" ] || [ "$BACKUPTYPE" = "remote" ]
    then
        echo -e $(MESSAGELOG "info" "Starting full Nextcloud backup." True)
        # Check if user run the script with sudo
        CHECKROOTUSER

        # Create log folder
        CHECKLOGFOLDER

        # Deleting old logs
        REMOVEBACKUPLOG

        # Enabling maintenance mode
        NC_MAINTENANCEMODE "enable"

        # Full backup
        echo -e $(MESSAGELOG "info" "Creating Nextcloud database and config backup.")
        NC_DBCONFIGBACKUP

        # NextCloud variables
        NC_DATADIR=$(sudo grep "datadirectory" /var/snap/nextcloud/current/nextcloud/config/config.php  | awk '{print $3}' | tr -d "\',")
        NC_EXPORTEDBACKUPFULLPATH=$(grep "Successfully exported" ${LOGFOLDER}/${BACKUPLOG} | awk '{print $3}')
        NC_EXPORTEDBACKUPFILENAME=$(grep "Successfully exported" ${LOGFOLDER}/${BACKUPLOG} | awk -F/ '{print $7}')
        NC_EXPORTEDBACKUPFOLDERNAME=$(dirname $(grep "Successfully exported" ${LOGFOLDER}/${BACKUPLOG} | awk '{print $3}'))

        echo -e $(MESSAGELOG "info" "Creating Nextcloud data backup.")
        NC_DATABACKUP

        # Move backup to a specific folder (optional)
        echo -e $(MESSAGELOG "info" "Moving Nextcloud backup under \"${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDBACKUPFILENAME}\"")
        NC_MOVEBACKUP
        echo -e $(MESSAGELOG "info" "Backup size: $(NC_BACKUPSIZE)")

        # Remote storage
        if [ "$BACKUPTYPE" = "remote" ]
        then
            echo -e $(MESSAGELOG "info" "Sending Nextcloud backup to a remote host.")
            SENDBACKUPRSYNC
        fi

        NC_MAINTENANCEMODE "disable" 
    else
        echo -e $(MESSAGELOG "error" "This argument only works with 'local' or 'remote' values.")
    fi
    shift
    exit 0
    ;;
-h|--help) 
    SHOWHELP
    exit 0
    ;;
-v|--version) 
    SHOWVERSION
    exit 0
    ;;
-V|--verbose)
    echo "coming soon"
    set -xv  # Set xtrace and verbose mode.
    ;;
*) 
    SHOWHELP
    exit 0
    ;;
--)
    shift
    break;;
esac
shift
done