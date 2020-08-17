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

NC_DBCONFIGBACKUP () {
    sudo nextcloud.export -abcd >> ${LOGFOLDER}/${BACKUPLOG} 2>&1
    if [ $? != 0 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs creating a Nextcloud database and config backup. Please check backup command.")
        exit 1
    else
        echo -e $(MESSAGELOG "success" "Nextcloud database and config backup created correctly.")
    fi
}

NC_DATABACKUP () {
    # rsync -azP --delete ${NC_DATADIR} ${NC_EXPORTEDBACKUPFOLDERNAME}
    rsync -azP --delete ${NC_DATADIR} ${NC_EXPORTEDBACKUPFOLDERNAME} >> ${LOGFOLDER}/${BACKUPLOG} 2>&1
    if [ $? != 0 ]
    then
        echo -e $(MESSAGELOG "error" "A problem occurs creating a Nextcloud data backup. Please check backup command.")
        exit 1
    else
        echo -e $(MESSAGELOG "success" "Nextcloud data backup created correctly.")
    fi
}

NC_MOVEBACKUP () {
    sudo mv -f "${NC_EXPORTEDBACKUPFULLPATH}" "${BACKUPSTORAGEFOLDER}"
    # sudo chown -R $(whoami):$(whoami) "${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDBACKUPFILENAME}"
    sudo chown -R $SUDO_USER:$SUDO_USER "${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDBACKUPFILENAME}"
}

NC_BACKUPSIZE () {
    du -sh ${BACKUPSTORAGEFOLDER}/${NC_EXPORTEDBACKUPFILENAME} | awk '{print $1}'
}

# NC_COMPRESSBACKUP () {
    # Tar.gz files and folders
    # CONFIGDBTARNAME="${NC_EXPORTEDBACKUPFILENAME}_DB_CONFIG.tar.gz"
    # CONFIGDBFULLPATHNAME="${BACKUPSTORAGEFOLDER}/${CONFIGDBTARNAME}"

    # echo -e $(MESSAGELOG "info" "Creating tar.gz file...")
    # sudo tar czf "${CONFIGDBFULLPATHNAME}" "${NC_EXPORTEDBACKUPFULLPATH}"
    # if [ $? = 0 ]
    # then
    #     # sudo ls -l "$NC_EXPORTEDBACKUPFOLDERNAME"
    #     echo -e $(MESSAGELOG "info" "Deleting original file: \"${NC_EXPORTEDBACKUPFULLPATH}\"")
    #     sudo rm -rf "$NC_EXPORTEDBACKUPFULLPATH"
    #     echo -e $(MESSAGELOG "success" "Config and DB backup created correctly: \"${BACKUPSTORAGEFOLDER}/${CONFIGDBTARNAME}\"")
    #     sudo chown test:test "${CONFIGDBFULLPATHNAME}"
    # else
    #     echo -e $(MESSAGELOG "error" "An error happened createing the TAR file from DB and CONFIG files.")
    #     exit 1
    # fi
# }

