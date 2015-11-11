#!/bin/bash

function set_version {
    if [ "x$1" == "x" ] 
    then
        EAP_VERSION=6.4.4
    else
        EAP_VERSION=$1
    fi

    if [ ! -f src/jboss-eap-$EAP_VERSION.patch ]
    then
        echo "Version $EAP_VERSION is not supported, versions supported are :" `find src -name '*.patch'|grep -Eo '[0-9]+\.[0-9]+\.[0-9]'`
        exit 1
    fi

    if [ -f dist/jboss-eap-$EAP_VERSION.zip ]
    then
        echo "EAP version $EAP_VERSION already built. If you wanna build it again, remove the dist/jboss-eap-$EAP_VERSION.zip file" 
        exit 0
    fi
    EAP_SHORT_VERSION=${EAP_VERSION%.*}
    SRC_FILE=jboss-eap-${EAP_VERSION/'-alpha'/'.Alpha'}-src.zip

    echo "Here we go. Building EAP version $EAP_VERSION."
}

function patch_files {
    echo "Patching files"
    echo "=== Patch ===" >> work/build.log
    patch -p0 < src/jboss-eap-$EAP_VERSION.patch >> work/build.log || { echo >&2 "Error applying patch.  Aborting."; exit 1; }
    # Downloading Maven before the build, so that I can override the settings.xml file
    if [ -f work/jboss-eap-$EAP_SHORT_VERSION-src/tools/download-maven.sh ]
    then
        cd work/jboss-eap-$EAP_SHORT_VERSION-src
        ./tools/download-maven.sh
        cd ../..
    fi
    cp src/settings.xml work/jboss-eap-$EAP_SHORT_VERSION-src/tools/maven/conf/
    cp src/build.conf work/jboss-eap-$EAP_SHORT_VERSION-src/
}

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
        exit 1
    fi
}

function maven_build {
    echo "Launching Maven build"
    echo "=== Maven ===" >> work/build.log
    cd work/jboss-eap-$EAP_SHORT_VERSION-src/
    ./build.sh -DskipTests -Drelease=true $1 >> ../build.log 2>&1
    cd ../.. 
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
