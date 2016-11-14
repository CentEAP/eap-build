#!/bin/bash

function set_version {
    if [ "x$1" == "x" ] 
    then
        EAP_VERSION=$(get_default_version)
    else
        EAP_VERSION=$1
        is_supported_version $EAP_VERSION
    fi

    if [ -f dist/jboss-eap-$EAP_VERSION.zip ]
    then
        echo "EAP version $EAP_VERSION already built. If you wanna build it again, remove the dist/jboss-eap-$EAP_VERSION.zip file" 
        exit 0
    fi
    EAP_SHORT_VERSION=${EAP_VERSION%.*}
    SRC_FILE=jboss-eap-${EAP_VERSION}-src.zip

    echo "Here we go. Building EAP version $EAP_VERSION."
}

function prepare_eap_source {
    download_and_unzip http://ftp.redhat.com/redhat/jbeap/$EAP_VERSION/en/source/$SRC_FILE
    cd work
    jboss-eap-$EAP_SHORT_VERSION-src/tools/download-maven.sh
    MVN=$PWD/maven/bin/mvn
    cd ..
}

function prepare_core_source {
    CORE_VERSION=$(get_module_version org.wildfly.core)
    CORE_FULL_SOURCE_VERSION=$(grep "$CORE_VERSION=" src/jboss-eap-7.properties | cut -d '=' -f 2)
    MAVEN_REPO=https://maven.repository.redhat.com/earlyaccess

    if [ -z "$CORE_FULL_SOURCE_VERSION" ]
    then
        echo "No WildFly Core source found for version $CORE_VERSION"
        exit 1
    fi
    download_and_unzip $MAVEN_REPO/org/wildfly/core/wildfly-core-parent/$CORE_FULL_SOURCE_VERSION/wildfly-core-parent-$CORE_FULL_SOURCE_VERSION-project-sources.tar.gz

    cd work
    mkdir wildfly-core-$CORE_VERSION
    cp -r wildfly-core-parent-$CORE_FULL_SOURCE_VERSION/core-feature-pack wildfly-core-$CORE_VERSION/
    cp wildfly-core-parent-$CORE_FULL_SOURCE_VERSION/checkstyle-suppressions.xml wildfly-core-$CORE_VERSION/core-feature-pack/

    cd wildfly-core-$CORE_VERSION/core-feature-pack

    wget $MAVEN_REPO/org/wildfly/core/wildfly-core-feature-pack/$CORE_VERSION/wildfly-core-feature-pack-$CORE_VERSION.pom -O pom.xml
    sed -i 's/ xmlns="http:\/\/maven.apache.org\/POM\/4.0.0"//g' pom.xml 
    xmlstarlet ed -d "//dependency[artifactId='wildfly-core-model-test-framework']" pom.xml > tmp.xml
    rm pom.xml
    mv tmp.xml pom.xml

    cd ../../..
}

function build_core {
    cd work/wildfly-core-$CORE_VERSION
    maven_build core-feature-pack
    cd ../..
    echo "Build done for Core $CORE_VERSION"
}

function build_eap {
    cd work/jboss-eap-$EAP_SHORT_VERSION-src
    maven_build servlet-feature-pack
    maven_build feature-pack
    maven_build dist
    cd ../..
    echo "Build done for EAP $EAP_VERSION"
}

function maven_build {
    if [ -n "$1" ]
    then
        echo "Launching Maven build for $1"
        cd $1
    else
        echo "Launching Maven build from root"
    fi

    if [ "$MVN_OUTPUT" = "2" ]
    then
        echo "=== Main Maven build ===" | tee -a ../build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true | tee -a ../build.log
    elif [ "$MVN_OUTPUT" = "1" ]
    then
        echo "=== Main Maven build ===" | tee -a ../build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true | tee -a ../build.log | grep -E "Building JBoss|Building WildFly|ERROR|BUILD SUCCESS"
    else
        echo "=== Main Maven build ===" >> ../build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true >> ../build.log 2>&1
    fi

    if [ -n "$1" ]
    then
        cd ..
    fi
}

function get_module_version {
    grep "<version.$1>" work/jboss-eap-7.0-src/pom.xml | sed -e "s/<version.$1>\(.*\)<\/version.$1>/\1/" | sed 's/ //g'
}

function is_supported_version {
    set +e
    supported_versions=$(get_supported_versions)
    supported_version=$(echo "$supported_versions," | grep -P "$1,")
    if [ -z $supported_version ]
    then
        echo "Version $1 is not supported. Supported versions are $supported_versions"
        exit 1
    fi
    set -e
}
function get_supported_versions {
    grep 'versions' src/jboss-eap-7.properties | sed -e "s/versions=//g"
}
function get_default_version {
    echo $(get_supported_versions) | sed s/,/\\n/g | sort | tac | sed -n '1p'
}

