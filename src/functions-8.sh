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
        log "EAP version $EAP_VERSION already built. If you wanna build it again, remove the dist/jboss-eap-$EAP_VERSION.zip file" 
        exit 0
    fi
    EAP_SHORT_VERSION=${EAP_VERSION%.*}
    SRC_FILE=jboss-eap-${EAP_VERSION}-src.zip
    BUILD_HOME=$(pwd)
    #echo BUILD_HOME=$BUILD_HOME

    log "Here we go. Building EAP version $EAP_VERSION."
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
    log "Core version: $CORE_VERSION"
    EAP_CORE_VERSION=$(grep "$EAP_VERSION.core=" src/jboss-eap-8.properties | cut -d '=' -f 2)

    if [ -z "$EAP_CORE_VERSION" ]
    then
        EAP_CORE_VERSION=$EAP_VERSION
    fi
    download_and_unzip http://ftp.redhat.com/redhat/jboss/eap/$EAP_CORE_VERSION/en/source/jboss-eap-$EAP_CORE_VERSION-core-src.zip
    mv $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-core-src $BUILD_HOME/work/wildfly-core-$CORE_VERSION

    cd $BUILD_HOME/work/wildfly-core-$CORE_VERSION/core-feature-pack

    xml_clean core
    create_modules .

    cd $BUILD_HOME
}

function build_core {
    cd $BUILD_HOME/work/wildfly-core-$CORE_VERSION
    maven_build core-feature-pack
    cd $BUILD_HOME
    log "Build done for Core $CORE_VERSION"
}

function build_eap {
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src
    maven_build ee-feature-pack
    mv ee-dist dist
    maven_build dist
    cd $BUILD_HOME
    log "Build done for EAP $EAP_VERSION"
}

function maven_build {
    settings=$(pwd)/../../src/settings.xml
    if [ -n "$1" ]
    then
        msg="Maven build for $1"
        cd $1
    else
        msg="Maven build from root"
    fi

    mvn_command="$MVN clean install -s $settings -Dmaven.test.skip -Drelease=true -Denforcer.skip"

    if [ "$MVN_OUTPUT" = "3" ]
    then
        echo "=== $msg (with output level $MVN_OUTPUT) ===" | tee -a $BUILD_HOME/work/build.log
        $mvn_command | tee -a $BUILD_HOME/work/build.log || error "Error in $msg"
        echo "...done with $msg" | tee -a $BUILD_HOME/work/build.log
    elif [ "$MVN_OUTPUT" = "2" ]
    then
        echo "=== $msg (with output level $MVN_OUTPUT) ===" | tee -a $BUILD_HOME/work/build.log
        $mvn_command | tee -a $BUILD_HOME/work/build.log | grep --invert-match --extended-regexp "Downloading:|Downloaded:" || error "Error in $msg"
        echo "...done with $msg" | tee -a $BUILD_HOME/work/build.log
    elif [ "$MVN_OUTPUT" = "1" ]
    then
        echo "=== $msg (with output level $MVN_OUTPUT) ===" | tee -a $BUILD_HOME/work/build.log
        $mvn_command | tee -a $BUILD_HOME/work/build.log | grep --extended-regexp "Building JBoss|Building WildFly|ERROR|BUILD SUCCESS" || error "Error in $msg"
        echo "...done with $msg" | tee -a $BUILD_HOME/work/build.log
    else
        echo "=== $msg ===" >> $BUILD_HOME/work/build.log
        $mvn_command >> $BUILD_HOME/work/build.log 2>&1 || error "Error in $msg"
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
    supported_version=$(echo "$supported_versions," | grep -E "$1,")
    if [ -z $supported_version ]
    then
        log "Version $1 is not supported. Supported versions are $supported_versions"
        exit 1
    fi
    set -e
}
function get_supported_versions {
    grep 'versions' src/jboss-eap-8.properties | sed -e "s/versions=//g"
}
function get_default_version {
    echo $(get_supported_versions) | sed s/,/\\n/g | tac | sed -n '1p'
}
function create_modules {
    module_names=$(grep "$EAP_VERSION.modules" $BUILD_HOME/src/jboss-eap-8.properties | sed -e "s/$EAP_VERSION.modules=//g")
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

    xml_to_delete=$(grep "$EAP_VERSION.xpath.delete.$scope" $BUILD_HOME/src/jboss-eap-8.properties | sed -e "s/$EAP_VERSION.xpath.delete.$scope=//g" | tr '\n' ' ')
    #echo xml_to_delete : $xml_to_delete
    IFS=' ' read -ra xml_to_delete_array <<< $xml_to_delete
    for line in "${xml_to_delete_array[@]}"; do
        xml_delete $(echo $line| sed -e "s/,/ /g")
    done

    xml_to_insert=$(grep "$EAP_VERSION.xpath.insert.$scope" $BUILD_HOME/src/jboss-eap-8.properties | sed -e "s/$EAP_VERSION.xpath.insert.$scope=//g" | tr '\n' ' ')
    #echo xml_to_insert : $xml_to_insert
    IFS=' ' read -ra xml_to_insert_array <<< $xml_to_insert
    for line in "${xml_to_insert_array[@]}"; do
        xml_insert $(echo $line| sed -e "s/,/ /g")
    done

    xml_to_update=$(grep "$EAP_VERSION.xpath.update.$scope" $BUILD_HOME/src/jboss-eap-8.properties | sed -e "s/$EAP_VERSION.xpath.update.$scope=//g" | tr '\n' ' ')
    IFS=' ' read -ra xml_to_update_array <<< $xml_to_update
    for line in "${xml_to_update_array[@]}"; do
        xml_update $(echo $line| sed -e "s/,/ /g")
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
    #echo xmlstarlet ed --insert "$xpath" --type elem --name "$value"
    xmlstarlet ed --insert "$xpath" --type elem --name "$value" .tmp.xml > $file
    rm .tmp.xml
}
function xml_update {
    #echo xml_update $*
    file=$1
    xpath=$2
    value="$3"

    cp $file .tmp.xml
    xmlstarlet ed --update $xpath --value $value .tmp.xml > $file
    rm .tmp.xml
}
function error {
    log >&2 $1
    echo >&2 ""
    log >&2 "Build failed. You may have a look at the work/build.log file, maybe you'll find the reason why it failed."
    exit 1
}
