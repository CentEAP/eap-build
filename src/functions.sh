#!/bin/bash

function check_command {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 is not installed.  Aborting."; exit 1; }
}

function download_and_unzip {    
    URL=$1
    FILENAME=${URL##*/}

    if [ ! -f download/$FILENAME ]
    then
        echo "Trying to download $FILENAME."
        wget --timeout=30 --tries=2 --directory-prefix=download $URL
    else
        echo "File $FILENAME already here. No need to download it again."
    fi


    if command -v md5sum >/dev/null
    then
        md5cmd="md5sum"
    elif command -v md5 >/dev/null
    then
        md5cmd="md5 -r"
    fi
    
    if [ ! -f src/$FILENAME.md5 ]
    then
        echo "WARN : no checksum available for $FILENAME : src/$FILENAME.md5"
    elif ! command -v $md5cmd >/dev/null 
    then
        echo "WARN : no checksum command available"
    else
        if [ -z "`$md5cmd download/$FILENAME | diff src/$FILENAME.md5 -`" ]
        then
            echo "Checksum verified for $FILENAME"
        else
            echo "==== FAIL ===="
            echo "Checksum verification failed for $FILENAME"
            echo "=============="
            exit 1	      
        fi
    fi

    if [ -f download/$FILENAME ]
    then
        echo "Unzipping $FILENAME"
        unzip -q -d work download/$FILENAME
        echo "$FILENAME unzipped"
    else
        echo "==== FAIL ===="
        echo "I'm unable to download the file. You could download the $MVN_FILE file from http://www.jboss.org/jbossas/downloads or https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?downloadType=distributions&product=appplatform&version=$EAP_VERSION (login required) and put it in the download directory."
        echo "=============="
        exit 1
    fi
}
