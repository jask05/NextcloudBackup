#!/usr/bin/env bash

################################## CAMBIOS #################################
#
# 1. echo por printf => https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
# 2.¿QUIET mode?
# 3. ¿Poner mensajes programas customizados para saber que no son mios?
#
#
#############################################################################

#################################### >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 
# CLEAN
sudo rm -rf /var/snap/nextcloud/common/backups/* /home/test/nextcloudbackup/* /home/testrsync/2020* /home/test/scripts/NextcloudBackup/logs
#################################### >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 

# Make Nextcloud Backup: DB, config folder and data

# Main config. NOT TOUCH !!!
TIMESTAMP=$(date +"%Y-%m-%d %T")
CLEANTIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUPTYPE=${1:-"Local"} # Local (default) or Remote
SCRIPTDIR=$(dirname "$0")
VERSION="0.5"

# RSYNC parameters
IDRSA="/home/test/.ssh/id_rsa"
REMOTEUSER="testrsync"
REMOTEHOST="127.0.0.1"
REMOTESTORAGEFOLDER="/home/testrsync/"

# Custom config
LOGFOLDER="${SCRIPTDIR}/logs"
BACKUPSTORAGEFOLDER="/home/test/nextcloudbackup"
PREFIXBACKUPLOG="nextcloudbackup"
SUFIXBACKUPLOG="${CLEANTIMESTAMP}.log"
BACKUPLOG="${PREFIXBACKUPLOG}_${SUFIXBACKUPLOG}"

# Functions
. "${SCRIPTDIR}/functions/main.sh"
. "${SCRIPTDIR}/functions/nextcloud.sh"

# Telegram notification
# Coming soon

# Wellcome banner
WELLCOMEBANNER

# >>>>>>>>>>>>>>>>>>>>> Solo si se escogió backup remoto
# CHECKANDSENDKEY

# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
# options=$(getopt -l "help,version:,verbose,rebuild,dryrun" -o "hv:Vrd" -a -- "$@")
options=$(getopt -l "help,version,verbose,backup-mode" -o "hvVb:" -a -- "$@")

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
        CHECKROOTUSER
        echo -e $(MESSAGELOG "info" "Starting backup." True)

        # Create log folder
        CHECKLOGFOLDER

        # Deleting old logs
        REMOVEBACKUPLOG

        # Enabling maintenance mode
        NC_MAINTENANCEMODE "enable"

        # Backup: config file and DB
        # Coming soon

        # Full backup
        echo -e $(MESSAGELOG "info" "Creating a full Nextcloud backup (data, db and config).")
        NC_FULLBACKUP

        # NextCloud variables
        # >> MEJORAR VARIABLES
        NC_EXPORTEDFULLPATH=$(grep "Successfully exported" ${LOGFOLDER}/${BACKUPLOG} | awk '{print $3}')
        NC_EXPORTEDFILENAME=$(grep "Successfully exported" ${LOGFOLDER}/${BACKUPLOG} | awk -F/ '{print $7}')
        NC_EXPORTEDFOLDERNAME=$(dirname $(grep "Successfully exported" ${LOGFOLDER}/${BACKUPLOG} | awk '{print $3}'))

        # Move backup to a specific folder
        # >>>>>>>>>>>> ¿Es necesario moverlo cuando es un full backup?
        echo -e $(MESSAGELOG "info" "Moving Nextcloud backup under \"${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDFILENAME}\"")
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
--)
    shift
    break;;
esac
shift
done