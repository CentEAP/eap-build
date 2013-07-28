#!/bin/bash

if [ "x$1" != "x" ]; then
    EAP_VERSION=$1
fi

if [ "x$EAP_VERSION" == "x" ]; then
    EAP_VERSION=6.0.1
fi

echo "Here we go. Will try to build EAP version $EAP_VERSION."

EAP_SHORT_VERSION=${EAP_VERSION%.*}
SRC_FILE=jboss-eap-$EAP_VERSION-src.zip
MVN_FILE=jboss-eap-$EAP_VERSION-maven-repository.zip

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
        echo "I'm unable to download the file. You could download the $MVN_FILE file from http://www.jboss.org/jbossas/downloads or https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?downloadType=distributions&product=appplatform&version=$EAP_VERSION (login required)"    
        echo "=============="
        exit 1
    fi
}

rm -rf build
mkdir build

download_and_unzip ftp://ftp.redhat.com/redhat/jbeap/$EAP_VERSION/en/source/$SRC_FILE
download_and_unzip http://maven.repository.redhat.com/techpreview/eap6/$EAP_VERSION/$MVN_FILE

patch -p0 < src/jboss-eap-$EAP_VERSION.patch
cp src/settings.xml build/jboss-eap-$EAP_SHORT_VERSION-src/tools/maven/conf/

export EAP_REPO_URL=file://`pwd`/build/jboss-eap-$EAP_VERSION-maven-repository/
cd build/jboss-eap-$EAP_SHORT_VERSION-src/
./build.sh -Drelease=true

cp -R dist/target/jboss-eap-6.0.1.ER4.zip ../
echo "Build done. Check your root directory for the eap zip file."
