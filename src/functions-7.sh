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
    BUILD_HOME=$(pwd)
    #echo BUILD_HOME=$BUILD_HOME

    echo "Here we go. Building EAP version $EAP_VERSION."
}

function prepare_eap_source {
    download_and_unzip http://ftp.redhat.com/redhat/jboss/eap/$EAP_VERSION/en/source/$SRC_FILE
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src
    xml_clean eap
    cd $BUILD_HOME/work
    if [ -f jboss-eap-$EAP_SHORT_VERSION-src/mvnw ] 
    then
        MVN=$PWD/jboss-eap-$EAP_SHORT_VERSION-src/mvnw
        export MAVEN_BASEDIR=$PWD/jboss-eap-$EAP_SHORT_VERSION-src
    else
        jboss-eap-$EAP_SHORT_VERSION-src/tools/download-maven.sh
        MVN=$PWD/maven/bin/mvn
    fi
    cd $BUILD_HOME
}

function prepare_core_source {
    CORE_VERSION=$(get_module_version org.wildfly.core)
    CORE_FULL_SOURCE_VERSION=$(grep "$CORE_VERSION=" src/jboss-eap-7.properties | cut -d '=' -f 2)
    MAVEN_REPO=https://maven.repository.redhat.com/earlyaccess

    if [ -z "$CORE_FULL_SOURCE_VERSION" ]
    then
        echo "No WildFly Core source found for version $CORE_VERSION"
        exit 1
    elif [[ $CORE_FULL_SOURCE_VERSION = *"-redhat-"* ]]
    then
        download_and_unzip $MAVEN_REPO/org/wildfly/core/wildfly-core-parent/$CORE_FULL_SOURCE_VERSION/wildfly-core-parent-$CORE_FULL_SOURCE_VERSION-project-sources.tar.gz
    else
        download_and_unzip http://repo1.maven.org/maven2/org/wildfly/core/wildfly-core-parent/$CORE_FULL_SOURCE_VERSION/wildfly-core-parent-$CORE_FULL_SOURCE_VERSION-source-release.zip
    fi

    cd $BUILD_HOME/work
    mkdir wildfly-core-$CORE_VERSION
    cp -r wildfly-core-parent-$CORE_FULL_SOURCE_VERSION/core-feature-pack wildfly-core-$CORE_VERSION/
    cp wildfly-core-parent-$CORE_FULL_SOURCE_VERSION/checkstyle-suppressions.xml wildfly-core-$CORE_VERSION/core-feature-pack/

    cd $BUILD_HOME/work/wildfly-core-$CORE_VERSION/core-feature-pack

    wget --output-file=$BUILD_HOME/work/build.log $MAVEN_REPO/org/wildfly/core/wildfly-core-feature-pack/$CORE_VERSION/wildfly-core-feature-pack-$CORE_VERSION.pom -O pom.xml
    xml_clean core

    create_modules .

    cd $BUILD_HOME
}

function build_core {
    cd $BUILD_HOME/work/wildfly-core-$CORE_VERSION
    maven_build core-feature-pack
    cd $BUILD_HOME
    echo "Build done for Core $CORE_VERSION"
}

function build_eap {
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src
    maven_build servlet-feature-pack
    maven_build feature-pack
    maven_build dist
    cd $BUILD_HOME
    echo "Build done for EAP $EAP_VERSION"
}

function maven_build {
    if [ -n "$1" ]
    then
        msg="Maven build for $1"
        cd $1
    else
        msg="Maven build from root"
    fi

    if [ "$MVN_OUTPUT" = "3" ]
    then
        echo "=== $msg (with output level $MVN_OUTPUT) ===" | tee -a $BUILD_HOME/work/build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true | tee -a $BUILD_HOME/work/build.log || error "Error in $msg"
	    echo "...done with $msg" | tee -a $BUILD_HOME/work/build.log
    elif [ "$MVN_OUTPUT" = "2" ]
    then
        echo "=== $msg (with output level $MVN_OUTPUT) ===" | tee -a $BUILD_HOME/work/build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true | tee -a $BUILD_HOME/work/build.log | grep --invert-match --extended-regexp "Downloading:|Downloaded:" || error "Error in $msg"
	    echo "...done with $msg" | tee -a $BUILD_HOME/work/build.log
    elif [ "$MVN_OUTPUT" = "1" ]
    then
        echo "=== $msg (with output level $MVN_OUTPUT) ===" | tee -a $BUILD_HOME/work/build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true | tee -a $BUILD_HOME/work/build.log | grep --extended-regexp "Building JBoss|Building WildFly|ERROR|BUILD SUCCESS" || error "Error in $msg"
	    echo "...done with $msg" | tee -a $BUILD_HOME/work/build.log
    else
        echo "=== $msg ===" >> $BUILD_HOME/work/build.log
        $MVN clean install -s ../../../src/settings.xml -DskipTests -Drelease=true >> $BUILD_HOME/work/build.log 2>&1 || error "Error in $msg"
	    echo "...done with $msg" >> $BUILD_HOME/work/build.log
    fi

    if [ -n "$1" ]
    then
        cd ..
    fi
}

function get_module_version {
    grep "<version.$1>" $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src/pom.xml | sed -e "s/<version.$1>\(.*\)<\/version.$1>/\1/" | sed 's/ //g'
}

function is_supported_version {
    set +e
    supported_versions=$(get_supported_versions)
    supported_version=$(echo "$supported_versions," | grep -G "$1,")
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
function create_modules {
    module_names=$(grep "$EAP_VERSION.modules" $BUILD_HOME/src/jboss-eap-7.properties | sed -e "s/$EAP_VERSION.modules=//g")
    IFS=',' read -ra module_names_array <<< $module_names
    for module_name in "${module_names_array[@]}"; do
        create_module $module_name $1
    done
}
function create_module {
    # Create an empty jboss module
    module_name=$1
    module_dir=$2/src/main/resources/modules/system/layers/base/$(echo $module_name | sed 's:\.:/:g')/main
    mkdir -p $module_dir
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<module xmlns=\"urn:jboss:module:1.3\" name=\"$module_name\">\n</module>" > $module_dir/module.xml
}

function xml_clean {
    scope=$1

    xml_to_delete=$(grep "$EAP_VERSION.xpath.delete.$scope" $BUILD_HOME/src/jboss-eap-7.properties | sed -e "s/$EAP_VERSION.xpath.delete.$scope=//g" | tr '\n' ' ')
    #echo xml_to_delete : $xml_to_delete
    IFS=' ' read -ra xml_to_delete_array <<< $xml_to_delete
    for line in "${xml_to_delete_array[@]}"; do
        xml_delete $(echo $line| sed -e "s/,/ /g")
    done

    xml_to_insert=$(grep "$EAP_VERSION.xpath.insert.$scope" $BUILD_HOME/src/jboss-eap-7.properties | sed -e "s/$EAP_VERSION.xpath.insert.$scope=//g" | tr '\n' ' ')
    #echo xml_to_insert : $xml_to_insert
    IFS=' ' read -ra xml_to_insert_array <<< $xml_to_insert
    for line in "${xml_to_insert_array[@]}"; do
        xml_insert $(echo $line| sed -e "s/,/ /g")
    done
}
function xml_delete {
    #echo xml_delete $*
    file=$1
    xpath=$2

    cp $file .tmp.xml
    xmlstarlet ed --delete $xpath .tmp.xml > $file
    rm .tmp.xml
}
function xml_insert {
    #echo xml_insert $*
    file=$1
    xpath=$2
    value="$3 $4"

    cp $file .tmp.xml
    xmlstarlet ed --insert "$xpath" --type elem --name "$value" .tmp.xml > $file
    rm .tmp.xml
}
function error {
    echo >&2 $1
    echo >&2 ""
    echo >&2 "Build failed. You may have a look at the work/build.log file, maybe you'll find the reason why it failed."
    exit 1
}
