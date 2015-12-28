#!/bin/bash

function set_version {
    if [ "x$1" == "x" ] 
    then
        EAP_VERSION=6.4.5
    else
        EAP_VERSION=$1
    fi

    if [ ! -f src/jboss-eap-$EAP_VERSION.patch ]
    then
        echo "Version $EAP_VERSION is not supported, versions supported are :" `f   ind src -name '*.patch'|grep -Eo '[0-9]+\.[0-9]+\.[0-9](-[a-z]*)?'`
        exit 1
    fi

    if [ -f dist/jboss-eap-$EAP_VERSION.zip ]
    then
        echo "EAP version $EAP_VERSION already built. If you wanna build it again, remove the dist/jboss-eap-$EAP_VERSION.zip file" 
        exit 0
    fi
    EAP_SHORT_VERSION=${EAP_VERSION%.*}
    SRC_FILE=jboss-eap-${EAP_VERSION}-src.zip
    SRC_FILE=${SRC_FILE/'-alpha'/'.Alpha'}
    SRC_FILE=${SRC_FILE/'-beta'/'.Beta'}

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
        ./tools/download-maven.sh >/dev/null
        cd ../..
    fi
    if grep -q '-beta' <<<$EAP_VERSION
    then
        cp src/settings-ea.xml work/jboss-eap-$EAP_SHORT_VERSION-src/tools/maven/conf/settings.xml
        # Maybe a wrong version in EAP 7.0.0-beta pom.xml
        find work/jboss-eap-$EAP_SHORT_VERSION-src/ -type f -print0 | xargs -0 sed -i 's/redhat-SNAPSHOT/redhat-1/g'
    else
        cp src/settings.xml work/jboss-eap-$EAP_SHORT_VERSION-src/tools/maven/conf/settings.xml
    fi
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
        echo "Unzipping $FILENAME"
        unzip -q -d work download/$FILENAME
        echo "$FILENAME unzipped"
    else
        exit 1
    fi
}

function build_core {
    CORE_EAP_VERSION=$(get_module_version org.wildfly.core)
    CORE_PUBLIC_VERSION=${CORE_EAP_VERSION%%-redhat*}

    if [ -z "$CORE_PUBLIC_VERSION" ]
    then
        echo "No WildFly Core version found, skipping!"
    else
        download_and_unzip "https://github.com/wildfly/wildfly-core/archive/$CORE_PUBLIC_VERSION.zip"
        cd work/wildfly-core-$CORE_PUBLIC_VERSION/core-feature-pack
        wget https://maven.repository.redhat.com/earlyaccess/org/wildfly/core/wildfly-core-feature-pack/$CORE_EAP_VERSION/wildfly-core-feature-pack-$CORE_EAP_VERSION.pom -O pom.xml

        echo "Launching Maven build for core"
        if [ "$MVN_OUTPUT" = "2" ]
        then
            echo "=== Maven build for core ===" | tee -a ../../build.log
            mvn install -s ../../../src/settings-ea.xml | tee -a ../../build.log
        elif [ "$MVN_OUTPUT" = "1" ]
        then
            echo "=== Maven build for core ===" | tee -a ../../build.log
            mvn install -s ../../../src/settings-ea.xml | tee -a ../../build.log | grep -E "Building JBoss|Building WildFly|ERROR|BUILD SUCCESS"
        else
            echo "=== Maven build for core ===" >> ../../build.log
            mvn install -s ../../../src/settings-ea.xml >> ../../build.log 2>&1
        fi
        cd ../../..
    fi
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

function get_module_version {
    grep "<version.$1>" work/jboss-eap-7.0-src/pom.xml | sed -e "s/<version.$1>\(.*\)<\/version.$1>/\1/" | sed 's/ //g'
}

