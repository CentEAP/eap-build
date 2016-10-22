#!/bin/bash

function check_commands {
    for arg in $*
    do
        check_command $arg
    done
}
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

    # Cygwin
    if uname|grep -i cygwin >/dev/null
    then
        check_commands sed
        md5_check=`md5sum download/$FILENAME | sed 's/ \*/  /' | diff src/$FILENAME.md5 -`
    # Linux
    elif command -v md5sum >/dev/null
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
echo $1
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
        if [[ $FILENAME == *zip ]]
        then
            echo "Unzipping $FILENAME"
            unzip -q -d work download/$FILENAME
            echo "$FILENAME unzipped"
        else
            echo "Decompressing $FILENAME"
            tar -xzf download/$FILENAME -C work
            echo "$FILENAME decompressed"
        fi
    else
        exit 1
    fi
}

function save_result {
    # Copy zip files to the base dir, excluding the src files
    find work/jboss-eap-$EAP_SHORT_VERSION-src/dist/target \( ! -name "jboss*-src.zip" \) -a \( -name "jboss*.zip" \) -exec cp -f {} dist/jboss-eap-$EAP_VERSION.zip \;

    if [ -f dist/jboss-eap-$EAP_VERSION.zip ]
    then
        echo "Build done. Check your dist directory for the new eap zip file (jboss-eap-$EAP_VERSION.zip)."
        exit 0
    else
        echo "Build failed. You may have a look at the work/build.log file, maybe you'll find the reason why it failed."
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

