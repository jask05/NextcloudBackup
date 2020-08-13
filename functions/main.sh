#!/usr/bin/env bash

WELLCOMEBANNER () {
cat << "EOF"

 _   _           _   ____             _                
| \ | |         | | |  _ \           | |               
|  \| | _____  _| |_| |_) | __ _  ___| | ___   _ _ __  
| . ` |/ _ \ \/ / __|  _ < / _` |/ __| |/ / | | | '_ \ 
| |\  |  __/>  <| |_| |_) | (_| | (__|   <| |_| | |_) |
|_| \_|\___/_/\_\\__|____/ \__,_|\___|_|\_\\__,_| .__/  
                                                | |    
                                                |_|   
EOF
echo -e " Version: ${VERSION}\n"
}


# CHECKANDSENDKEY
# Check if RSA key does not exist 
# and send it to the remote host
CHECKANDSENDKEY () {
    if [ ! -f "$IDRSA" ]
    then
        ssh-keygen
        ssh-copy-id -i ${IDRSA} ${REMOTEUSER}@${REMOTEHOST}
    fi
}

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
    find ${LOGFOLDER} -iname ${PREFIXBACKUPLOG}\* -type f -delete
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

CHECKSWINSTALLED() {
    # check if rsync exists
    exit 0
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
            echo -e $(MESSAGELOG "success" "Backup folder was created correctly.")
        else
            echo -e $(MESSAGELOG "error" "Backup folder could not be created. Exit.")
            exit 1
        fi
    fi
}

CHECKLOGFOLDER () {
    if [ -d $LOGFOLDER ]
    then
        echo -e $(MESSAGELOG "info" "Log folder \"$LOGFOLDER\" exists.")
    else
        echo -e $(MESSAGELOG "warn" "Log folder does not exist. Trying to create it...")
        mkdir -p $LOGFOLDER
        if [ $? -eq 0 ]
        then
            echo -e $(MESSAGELOG "success" "Log folder was created correctly.")
        else
            echo -e $(MESSAGELOG "error" "Log folder could not be created. Exit.")
            exit 1
        fi
    fi
}

CHECKREMOTEPARAMETERS () {
    if [ -z "${REMOTEUSER// }" ] || [ -z "${REMOTEHOST// }" ] || [ -z "${REMOTESTORAGEFOLDER// }" ]
    then
        echo -e $(MESSAGELOG "error" "Please check \"remote user\", \"remote host\" or \"remote folder\" parameters.")
        exit 1
    fi
}

SENDBACKUPRSYNC () {
    rsync -a --no-motd --compress --log-file="${LOGFOLDER}/rsync.log" -e "ssh -o StrictHostKeyChecking=no -i ${IDRSA}" ${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDFILENAME} ${REMOTEUSER}@${REMOTEHOST}:${REMOTESTORAGEFOLDER}
    if [ $? = 0 ]
    then
        echo -e $(MESSAGELOG "success" "Nextcloud backup sended correctly.")
        echo -e $(MESSAGELOG "info" "Remote host: \"${REMOTEHOST}\". Remote folder: \"${REMOTESTORAGEFOLDER}${NC_EXPORTEDFILENAME}\"")

        # Delete local backup folder
        echo -e $(MESSAGELOG "info" "Deleting local backup folder.")
        rm -rf ${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDFILENAME}
        if [ $? -eq 0 ]
        then
            echo -e $(MESSAGELOG "success" "Local backup folder was deleted correctly.")
            sleep 5
        else
            echo -e $(MESSAGELOG "error" "Local backup folder could not be deleted. Please, check the commande.")
        fi
    else
        echo -e $(MESSAGELOG "error" "An error happened sending Nextcloud backup.")
        exit 1
    fi

    # --msgs2stderr            output messages directly to stderr
    # --quiet, -q              suppress non-error messages
    # --update, -u             skip files that are newer on the receiver
 }

SHOWHELP () {
cat << EOF  
Usage: ./nextbackup.sh [OPTION]...
Create a local o remote Nextcloud backup (only snap installation)
    -h, -help,          --help                  Display help
    -v, -version,       --version               Set and Download specific version of EspoCRM
    -b, -backup-mode,   --backup-mode           Specify backup mode: local or remote
    -V, -verbose,       --verbose               Run script in verbose mode. Will print out each step of execution.
EOF
}

SHOWVERSION () {
cat << EOF
nextcloudbackup ${VERSION} 
Copyright (C) 2020 
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Agustín Bulgarelli.
EOF
}