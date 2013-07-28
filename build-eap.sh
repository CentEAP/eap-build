#!/bin/bash

echo "Here we go. Will try to build EAP version 6.0.1."

SRC_FILE=jboss-eap-6.0.1-src.zip
MVN_FILE=jboss-eap-6.0.1-maven-repository.zip

function download_and_unzip {
    URL=$1
    FILENAME=${URL##*/}
    if [ ! -f $FILENAME ]
    then
        echo "Trying to download $FILENAME."
        wget --timeout=30 --tries=2 $URL
    else
        echo "File $FILENAME already here. No need to download it again."
    fi
    if [ -f $FILENAME ]
    then
        echo "Unzipping $FILENAME"
        unzip -q -d build $FILENAME
        echo "$FILENAME unzipped"
    else
        echo "==== FAIL ===="
        echo "I'm unable to download the file. You could download the $MVN_FILE file from http://www.jboss.org/jbossas/downloads or https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?downloadType=distributions&product=appplatform&version=6.0.1 (login required)"    
        echo "=============="
        exit 1
    fi
}

rm -rf build
mkdir build

download_and_unzip ftp://ftp.redhat.com/redhat/jbeap/6.0.1/en/source/$SRC_FILE
download_and_unzip http://maven.repository.redhat.com/techpreview/eap6/6.0.1/$MVN_FILE

cd build/jboss-eap-6.0.1-maven-repository/
patch -p 1 < ../../src/jboss-eap-6.0.1-maven-repository.patch
cd ../..
cp src/settings.xml build/jboss-eap-6.0-src/tools/maven/conf/

export EAP_REPO_URL=file://`pwd`/build/jboss-eap-6.0.1-maven-repository/
cd build/jboss-eap-6.0-src/
./build.sh -Drelease=true

cp -R dist/target/jboss-eap-6.0.1.ER4.zip ../
