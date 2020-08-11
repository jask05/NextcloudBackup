#!/usr/bin/env bash

################################## CAMBIOS #################################
#
# 1. echo por printf => https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
# 2.¿QUIET mode?
# 3. ¿Poner mensajes programas customizados para saber que no son mios?
#
#
#############################################################################

# Make Nextcloud Backup: DB, config folder and data

# Main config. NOT TOUCH !!!
TIMESTAMP=$(date +"%Y-%m-%d %T")
CLEANTIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUPTYPE=${1:-"Local"} # Local (default) or Remote

# Custom config
BACKUPSTORAGEFOLDER="/home/test/nextcloudbackup"
PREFIXBACKUPLOG="nextcloudbackup"
SUFIXBACKUPLOG="${CLEANTIMESTAMP}.log"
BACKUPLOG="${PREFIXBACKUPLOG}_${SUFIXBACKUPLOG}"

# MESSAGELOG function
# Param 1 => message type: info, warn, error, verbose
# Param 2 => text
# Param 3 => verbose (timestamp): True or False (default)
# Example: echo -e $(MESSAGELOG "info" "Starting backup." True)
MESSAGELOG () {
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

REMOVEBACKUPLOG () {
    find . -iname ${PREFIXBACKUPLOG}\* -type f -delete
}

CHECKROOTUSER () {
    if [ "$EUID" != 0 ]
    then
        sudo -k
        if sudo true
        then
            echo -e $(MESSAGELOG "success" "Correct password.")
        else
            echo -e $(MESSAGELOG "error" "Incorrect password. Finishing...")
            exit 1
        fi
    fi
}

# Checking if backup folder exists
CHECKBACKUPFOLDER () {
    if [ -d $BACKUPSTORAGEFOLDER ]
    then
        echo -e $(MESSAGELOG "info" "Backup folder \"$BACKUPSTORAGEFOLDER\" exists.")
    else
        echo -e $(MESSAGELOG "warn" "Backup folder does not exist. Trying to create it...")
        mkdir -p $BACKUPSTORAGEFOLDER
        if [ $? -eq 0 ]
        then
            echo -e $(MESSAGELOG "info" "Backup folder was created correctly.")
        else
            echo -e $(MESSAGELOG "error" "Backup folder could not be created. Exit.")
            exit 1
        fi
    fi
}

NC_MAINTENANCEMODE () {
    MODE=$1 # enable or disable
    if [ "$MODE" = "enable" ]
    then
        echo -e $(MESSAGELOG "info" "Enabling maintenance mode.")
        sudo nextcloud.occ maintenance:mode --on >> ${BACKUPLOG} 2>&1
    else
        if [ "$MODE" = "disable" ]
        then
            echo -e $(MESSAGELOG "info" "Disabling maintenance mode.")
            sudo nextcloud.occ maintenance:mode --off >> ${BACKUPLOG} 2>&1
        fi
    fi

    if [ $? -eq 1 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs enabling/disabling maintenance mode.")
    fi
}

NC_FULLBACKUP () {
    # sudo nextcloud.export -abcd | tee ${BACKUPLOG} # ¿se puede exportar a una variable?
    sudo nextcloud.export -abcd >> ${BACKUPLOG} 2>&1 # ¿se puede exportar a una variable?
    if [ $? != 0 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs creating a full Nextcloud backup. Please check backup command.")
        exit 1
    else
        echo -e $(MESSAGELOG "success" "Nextcloud full backup created correctly.")
    fi
}

NC_BACKUPDBANDCONFIG () {
    sudo nextcloud.export -abc | tee backup.log # ¿se puede exportar a una variable? https://stackoverflow.com/questions/10319745/redirecting-command-output-to-a-variable-in-bash-fails
    if [ $? != 0 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs creating backup (DB and Config). Please check Nextcloud export command.")
        exit 1
    fi
}

NC_BACKUPDATA () {
    sudo nextcloud.export -d | tee databackup.log # ¿se puede exportar a una variable?
    if [ $? != 0 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs creating data backup. Please check backup command.")
        exit 1
    fi
}

NC_MOVEBACKUP () {
    # echo "mv -fv" "${NC_EXPORTEDFULLPATH}" "${BACKUPSTORAGEFOLDER}"
    sudo mv -f "${NC_EXPORTEDFULLPATH}" "${BACKUPSTORAGEFOLDER}"
    sudo chown -R $(whoami):$(whoami) "${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDFILENAME}"
    # ls -l "${BACKUPSTORAGEFOLDER}"
}

NC_BACKUPSIZE () {
    du -sh ${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDFILENAME} | awk '{print $1}'
}

# NC_COMPRESSBACKUP () {
    # Tar.gz files and folders
    # CONFIGDBTARNAME="${NC_EXPORTEDFILENAME}_DB_CONFIG.tar.gz"
    # CONFIGDBFULLPATHNAME="${BACKUPSTORAGEFOLDER}/${CONFIGDBTARNAME}"

    # echo -e $(MESSAGELOG "info" "Creating tar.gz file...")
    # sudo tar czf "${CONFIGDBFULLPATHNAME}" "${NC_EXPORTEDFULLPATH}"
    # if [ $? = 0 ]
    # then
    #     # sudo ls -l "$NC_EXPORTEDFOLDERNAME"
    #     echo -e $(MESSAGELOG "info" "Deleting original file: \"${NC_EXPORTEDFULLPATH}\"")
    #     sudo rm -rf "$NC_EXPORTEDFULLPATH"
    #     echo -e $(MESSAGELOG "success" "Config and DB backup created correctly: \"${BACKUPSTORAGEFOLDER}/${CONFIGDBTARNAME}\"")
    #     sudo chown test:test "${CONFIGDBFULLPATHNAME}"
    # else
    #     echo -e $(MESSAGELOG "error" "An error happened createing the TAR file from DB and CONFIG files.")
    #     exit 1
    # fi
# }

# Telegram notification
# Coming soon

# Wellcome banner
# cat banner
cat << "EOF"
  _   _           _   ____             _                
 | \ | |         | | |  _ \           | |               
 |  \| | _____  _| |_| |_) | __ _  ___| | ___   _ _ __  
 | . ` |/ _ \ \/ / __|  _ < / _` |/ __| |/ / | | | '_ \ 
 | |\  |  __/>  <| |_| |_) | (_| | (__|   <| |_| | |_) |
 |_| \_|\___/_/\_\\__|____/ \__,_|\___|_|\_\\__,_| .__/   v0.3
                                                 | |    
                                                 |_|    
EOF

# Checking if the user is root or sudo
CHECKROOTUSER
echo -e $(MESSAGELOG "info" "Starting backup." True)

# Deleting old script log
# REMOVEBACKUPLOG
REMOVEBACKUPLOG

# Enabling maintenance mode
NC_MAINTENANCEMODE "enable"

# Config file backup and BD
# More info: https://github.com/nextcloud/nextcloud-snap/wiki/How-to-backup-your-instance
# NC_BACKUPDBANDCONFIG

# Full backup
echo -e $(MESSAGELOG "info" "Creating a full Nextcloud backup (data, db and config).")
NC_FULLBACKUP

# NextCloud variables
# >> MEJORAR VARIABLES
NC_EXPORTEDFULLPATH=$(grep "Successfully exported" ${BACKUPLOG} | awk '{print $3}')
NC_EXPORTEDFILENAME=$(grep "Successfully exported" ${BACKUPLOG} | awk -F/ '{print $7}')
NC_EXPORTEDFOLDERNAME=$(dirname $(grep "Successfully exported" ${BACKUPLOG} | awk '{print $3}'))

# >>>>>>>>>>>>>>>>>>>>>>>>>>>> Ponerlo para el modo VERBOSE del script
# echo ">> NC_EXPORTEDFULLPATH: $NC_EXPORTEDFULLPATH"
# echo ">> NC_EXPORTEDFOLDERNAME: $NC_EXPORTEDFOLDERNAME"
# echo ">> NC_EXPORTEDFILENAME: $NC_EXPORTEDFILENAME"
# echo ">> BACKUPSTORAGEFOLDER: $BACKUPSTORAGEFOLDER"
# exit 1

# Move backup folder
echo -e $(MESSAGELOG "info" "Moving Nextcloud backup under \"${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDFILENAME}\"")
NC_MOVEBACKUP
echo -e $(MESSAGELOG "info" "Backup size: $(NC_BACKUPSIZE)")

# Incremental data backup

# Disabling maintenance mode 
