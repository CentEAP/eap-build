#!/bin/bash

function check_command {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 is not installed.  Aborting."; exit 1; }
}
check_command wget
check_command unzip
check_command patch
check_command javac

if [ "x$1" == "x" ] 
then
    EAP_VERSION=6.2.0
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

echo "Here we go. Building EAP version $EAP_VERSION."

EAP_SHORT_VERSION=${EAP_VERSION%.*}
SRC_FILE=jboss-eap-$EAP_VERSION-src.zip
MVN_FILE=jboss-eap-$EAP_VERSION-maven-repository.zip

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

    if [ -f src/$FILENAME.md5 ]
    then
        if [ -z "`md5 -r download/$FILENAME | diff src/$FILENAME.md5 -`" ]
        then
            echo "Checksum verified for $FILENAME"
        else
            echo "==== FAIL ===="
            echo "Checksum verification failed for $FILENAME"
            echo "=============="
            exit 1	      
        fi
    else
        echo "WARN : no checksum available for $FILENAME : src/$FILENAME.md5"
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

rm -rf work
mkdir work
if [ ! -d download ]
then
    mkdir download
fi    
if [ ! -d dist ]
then
    mkdir dist
fi

download_and_unzip ftp://ftp.redhat.com/redhat/jbeap/$EAP_VERSION/en/source/$SRC_FILE
download_and_unzip http://maven.repository.redhat.com/techpreview/eap6/$EAP_VERSION/$MVN_FILE

echo "Patching files"
echo "=== Patch ===" >> work/build.log
patch -p0 < src/jboss-eap-$EAP_VERSION.patch >> work/build.log
cp src/settings.xml work/jboss-eap-$EAP_SHORT_VERSION-src/tools/maven/conf/

if [ $EAP_SHORT_VERSION == 6.0 ]
then
    export EAP_REPO_URL=file://`pwd`/work/jboss-eap-$EAP_VERSION-maven-repository/
else
    export EAP_REPO_URL=file://`pwd`/work/jboss-eap-$EAP_VERSION.GA-maven-repository/
fi
echo "Launching Maven build"
echo "=== Maven ===" >> work/build.log
cd work/jboss-eap-$EAP_SHORT_VERSION-src/
./build.sh -DskipTests -Drelease=true >> ../build.log 2>&1
cd ../..

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
