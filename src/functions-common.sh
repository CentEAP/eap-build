#!/bin/bash

function check_commands {
    for arg in $*
    do
        check_command $arg
    done
}
function check_command {
    command -v $1 >/dev/null 2>&1 || { log >&2 "$1 is not installed.  Aborting."; exit 1; }
}

function check_md5 {
    FILENAME=$1
    STATUS=0

    if [ ! -f download/$FILENAME.md5 ]
    then
        log "WARN : no checksum available for $FILENAME : download/$FILENAME.md5"
        return
    fi

    # Linux and Cygwin
    if command -v md5sum >/dev/null
    then
        md5sum --quiet -c download/$FILENAME.md5 || STATUS=$?
    # MacOS : beware the double space
    elif command -v md5 >/dev/null
    then
        check_commands cut
        if [ "$(md5 -q download/$FILENAME)" != "$(cat download/$FILENAME.md5 | cut -d ' ' -f 1)" ]
    	then
            STATUS=1
        fi
    else
        log "WARN : no checksum command available"
        return
    fi

    if [ "$STATUS" == "0" ]
    then
        log "Checksum verified for $FILENAME"
    else
        log "==== FAIL ===="
        log "Checksum verification failed for $FILENAME"
        log "=============="
        exit 1	      
    fi
}

function download_md5 {
    URL=$1
    FILENAME=${URL##*/}
    DIR_URL=${URL%/*}
    STATUS=0

    if [[ "$URL" == *"ftp.redhat.com"* ]]
    then
        wget --output-file=$BUILD_HOME/work/build.log -O download/$FILENAME.md5 $DIR_URL/MD5SUM || STATUS=$?
        sed -i.tmp  "s/$FILENAME/download\/$FILENAME/g" download/$FILENAME.md5
        sed -i.tmp "/$FILENAME/!d" download/$FILENAME.md5

    else
        wget --output-file=$BUILD_HOME/work/build.log -O download/$FILENAME.md5 $DIR_URL/$FILENAME.md5 || STATUS=$?
        echo "  download/$FILENAME" >> download/$FILENAME.md5 
    fi 

    if [ "$STATUS" != "0" ] 
    then
        rm download/$FILENAME.md5 
    fi
}

function download_and_unzip {
    URL=$1
    FILENAME=${URL##*/}
    
    if [ ! -f download/$FILENAME ]
    then
        log "Trying to download $FILENAME from $URL."
        wget --output-file=$BUILD_HOME/work/build.log --timeout=30 --tries=2 --directory-prefix=download $URL
    else
        log "File $FILENAME already here. No need to download it again."
    fi

    download_md5 $URL
    check_md5 $FILENAME

    if [ -f download/$FILENAME ]
    then
        if [[ $FILENAME == *zip ]]
        then
            log "Unzipping $FILENAME"
            unzip -q -d work download/$FILENAME
            log "$FILENAME unzipped"
        else
            log "Decompressing $FILENAME"
            tar -xzf download/$FILENAME -C work
            log "$FILENAME decompressed"
        fi
    else
        log "Download failed."
        exit 1
    fi
}

function save_result {
    # Copy zip files to the base dir, excluding the src files
    find work/jboss-eap-$EAP_SHORT_VERSION-src/dist/target \( ! -name "jboss*-src.zip" \) -a \( -name "jboss*.zip" \) -exec cp -f {} dist/jboss-eap-$EAP_VERSION.zip \;

    if [ -f dist/jboss-eap-$EAP_VERSION.zip ]
    then
        log "Build done. Check your dist directory for the new eap zip file (jboss-eap-$EAP_VERSION.zip)."
        exit 0
    else
        log "Build failed. You may have a look at the work/build.log file, maybe you'll find the reason why it failed."
        exit 1
    fi
}

function make_directory {
    if [ $1 == "-f" ]
    then
        rm -rf $2
        mkdir $2
    elif [ ! -d $1 ]
    then
        mkdir $1
    fi    
}

function portable_dos2unix {
	cat $1 | col -b > tmp.file
	mv tmp.file $1
}

function log {
    now=$(date --date now +"%H:%M:%S")
    echo "$now - $1"
}
