#!/bin/bash

function check_command {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 is not installed.  Aborting."; exit 1; }
}

function check_md5 {
    FILENAME=$1

    if [ ! -f src/$FILENAME.md5 ]
    then
        echo "WARN : no checksum available for $FILENAME : src/$FILENAME.md5"
        return
    fi

    # Linux
    if command -v md5sum >/dev/null
    then
        md5_check=`md5sum download/$FILENAME | diff src/$FILENAME.md5 -`
    # MacOS : beware the double space
    elif command -v md5 >/dev/null
    then
        md5_check=`md5 -r download/$FILENAME | sed 's/ /  /' | diff src/$FILENAME.md5 -`
    else
        echo "WARN : no checksum command available"
        return
    fi

    if [ -z "$md5_check" ]
    then
        echo "Checksum verified for $FILENAME"
    else
        echo "==== FAIL ===="
        echo "Checksum verification failed for $FILENAME"
        echo "=============="
        exit 1	      
    fi
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

    check_md5 $FILENAME

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


