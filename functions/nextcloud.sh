#!/usr/bin/env bash

NC_MAINTENANCEMODE () {
    MODE=$1 # enable or disable
    if [ "$MODE" = "enable" ]
    then
        echo -e $(MESSAGELOG "info" "Enabling maintenance mode.")
        sudo nextcloud.occ maintenance:mode --on >> ${LOGFOLDER}/${BACKUPLOG} 2>&1
    else
        if [ "$MODE" = "disable" ]
        then
            echo -e $(MESSAGELOG "info" "Disabling maintenance mode.")
            sudo nextcloud.occ maintenance:mode --off >> ${LOGFOLDER}/${BACKUPLOG} 2>&1
        fi
    fi

    if [ $? -eq 1 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs enabling/disabling maintenance mode.")
    fi
}

NC_FULLBACKUP () {
    sudo nextcloud.export -abcd >> ${LOGFOLDER}/${BACKUPLOG} 2>&1 # ¿se puede exportar a una variable?
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

