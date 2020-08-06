#!/usr/bin/env bash

################################## CAMBIOS #################################
#
# 1. echo por printf => https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
# 2.¿QUIET mode?
# 3. ¿Poner mensajes programas customizados para saber que no son mios?
#
#
#############################################################################

# Make Nextcloud Backup: BD, config folder and data

#########

TIMESTAMP=$(date +"%Y-%m-%d %T")
BACKUPFOLDER="/home/test/nextcloudbackup" # Add slash at the end of the folder name.
WORKDIR=$(pwd)

#########

# MessageLog function
# Param 1 => message type: info, warn, error, verbose
# Param 2 => text
# Param 3 => verbose (timestamp): True or False (default)
# Example: echo -e $(messageLog "info" "Starting backup." True)
messageLog () {
    # Colors
    local error="\033[1;31m"
    local warn="\033[1;33m"
    local info="\033[1;34m"
    local success="\033[1;32m"
    local nocolor="\033[0m"

    local type=$1
    local text=$2
    local verbose=${3:-False}


    case $type in
        error | ERROR)
            message="$error[+] ERROR: $nocolor"
            ;;
        warn | warning | WARN)
            message="$warn[+] WARN: $nocolor"
            ;;
        info | information | INFO)
            message="$info[+] INFO: $nocolor"
            ;;
        success | SUCCESS)
            message="$success[+] SUCCESS: $nocolor"
            ;;
    esac

    if [ "$verbose" == True ]
    then
        echo "$message$text $TIMESTAMP"
    else
        echo "$message$text"
    fi
}

NC_enableMaintenanceMode () {
    echo -e $(messageLog "info" "Enabling maintenance mode.")
    sudo nextcloud.occ maintenance:mode --on
    if [ $? -eq 1 ]
    then
        echo -e $(messageLog "error" "A problem occurs enabling maintenance mode.")
    fi
}

NC_disableMaintenanceMode () {
    echo -e $(messageLog "info" "Disabling maintenance mode.")
    sudo nextcloud.occ maintenance:mode --off
    if [ $? -eq 1 ]
    then
        echo -e $(messageLog "error" "A problem occurs enabling maintenance mode.")
    fi
}


# Wellcome banner
cat banner

# Checking if the user is root or sudo
if [ "$EUID" != 0 ]
then
    sudo -k
    if sudo true
    then
        echo -e $(messageLog "success" "Correct password.")
    else
        echo -e $(messageLog "error" "Incorrect password. Finishing...")
        exit 1
    fi
fi

echo -e $(messageLog "info" "Starting backup." True)

# Checking if backup folder exists
if [ -d $BACKUPFOLDER ]
then
    echo -e $(messageLog "info" "Backup folder \"$BACKUPFOLDER\" exists.")
else
    echo -e $(messageLog "warn" "Backup folder does not exist. Trying to create it...")
    mkdir -p $BACKUPFOLDER
    if [ $? -eq 0 ]
    then
        echo -e $(messageLog "info" "Backup folder was created correctly.")
    else
        echo -e $(messageLog "error" "Backup folder could not be created. Exit.")
        exit 1
    fi
fi

# Enabling maintenance mode
NC_enableMaintenanceMode

# Config file backup and BD
# More info: https://github.com/nextcloud/nextcloud-snap/wiki/How-to-backup-your-instance
# sudo nextcloud.export -abc | tee backup.log # ¿se puede exportar a una variable?
# if [ $? != 0 ]
# then
#     echo -e $(messageLog "error" "A problem occurs creating backup. Please check Nextcloud export command.")
#     exit 1
# fi

# MEJORAR VARIABLES
NC_EXPORTEDFULLPATH=$(grep "Successfully exported" backup.log | awk '{print $3}')
NC_EXPORTEDFILENAME=$(grep "Successfully exported" backup.log | awk -F/ '{print $7}')
NC_EXPORTEDFOLDERNAME=$(dirname $(grep "Successfully exported" backup.log | awk '{print $3}'))
# rm -f "backup.log"

# Tar.gz files and folders
# Delete: tar: Removing leading `/' from member names
echo "NC_EXPORTEDFULLPATH: $NC_EXPORTEDFULLPATH"
echo "NC_EXPORTEDFOLDERNAME: $NC_EXPORTEDFOLDERNAME"
echo "NC_EXPORTEDFILENAME: $NC_EXPORTEDFILENAME"
echo "BACKUPFOLDER: $BACKUPFOLDER"

# sudo tar -zcvf "${BACKUPFOLDER}/${NC_EXPORTEDFILENAME}.tar.gz -C / ${NC_EXPORTEDFULLPATH}"
sudo tar -zcfv "${BACKUPFOLDER}/${NC_EXPORTEDFILENAME}.tar.gz -C /" "${NC_EXPORTEDFOLDERNAME}/""${NC_EXPORTEDFILENAME}"
exit 1
# if [ $? = 0 ]
# then
#     sudo ls -l "$NC_EXPORTEDFOLDERNAME"
#     sudo rm -rf "$NC_EXPORTEDFULLPATH"
#     sudo ls -l "$NC_EXPORTEDFOLDERNAME"
# fi

# ls -l "$BACKUPFOLDER"

# Data backup
# Re-Enabling maintenance mode
enableMaintenanceMode


# Disabling maintenance mode 
echo -e $(messageLog "info" "Maintenance mode disabled.")
# sudo nextcloud.occ maintenance:mode --off