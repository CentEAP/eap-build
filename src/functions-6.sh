#!/bin/bash

function set_version {
    if [ "x$1" == "x" ] 
    then
        EAP_VERSION=6.4.24
    else
        EAP_VERSION=$1
    fi

    if [ ! -f src/eap6-patches/jboss-eap-$EAP_VERSION.patch ]
    then
        echo "Version $EAP_VERSION is not supported, versions supported are :" `find src/eap6-patches -name '*.patch'|grep -Eo '[0-9]+\.[0-9]+\.[0-9]*(-[a-z]*)?'`
        exit 1
    fi

    if [ -f dist/jboss-eap-$EAP_VERSION.zip ]
    then
        echo "EAP version $EAP_VERSION already built. If you wanna build it again, remove the dist/jboss-eap-$EAP_VERSION.zip file" 
        exit 0
    fi
    EAP_SHORT_VERSION=${EAP_VERSION%.*}
    SRC_FILE=jboss-eap-${EAP_VERSION}-src.zip
    export BUILD_HOME=$(pwd)

    echo "Here we go. Building EAP version $EAP_VERSION."
}

function patch_files {
    echo "Patching files"
    echo "=== Patch ===" >> work/build.log
    patch -p0 < src/eap6-patches/jboss-eap-$EAP_VERSION.patch >> work/build.log || { echo >&2 "Error applying patch.  Aborting."; exit 1; }
    # Downloading Maven before the build, so that I can override the settings.xml file
    if [ -f work/jboss-eap-$EAP_SHORT_VERSION-src/tools/download-maven.sh ]
    then
        cd work/jboss-eap-$EAP_SHORT_VERSION-src
        ./tools/download-maven.sh >/dev/null
        cd ../..
    fi
    cp src/settings.xml work/jboss-eap-$EAP_SHORT_VERSION-src/tools/maven/conf/settings.xml
    cp src/build.conf work/jboss-eap-$EAP_SHORT_VERSION-src/
}

function maven_build {
    echo "Launching Maven build"
    cd work/jboss-eap-$EAP_SHORT_VERSION-src/
    if [ "$MVN_OUTPUT" = "2" ]
    then
        echo "=== Main Maven build ===" | tee -a ../build.log
         ./build.sh -DskipTests -Drelease=true $1 | tee -a ../build.log
    elif [ "$MVN_OUTPUT" = "1" ]
    then
        echo "=== Main Maven build ===" | tee -a ../build.log
         ./build.sh -DskipTests -Drelease=true $1 | tee -a ../build.log | grep -E "Building JBoss|Building WildFly|ERROR|BUILD SUCCESS"
    else
        echo "=== Main Maven build ===" >> ../build.log
        ./build.sh -DskipTests -Drelease=true $1 >> ../build.log 2>&1
    fi
    cd ../.. 
}

