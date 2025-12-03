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
        finished "EAP version $EAP_VERSION already built. If you wanna build it again, remove the dist/jboss-eap-$EAP_VERSION.zip file" 
    fi
    EAP_SHORT_VERSION=${EAP_VERSION%.*}
    SRC_FILE=jboss-eap-${EAP_VERSION}-src.zip
    export BUILD_HOME=$(pwd)

    log "Here we go. Building EAP version $EAP_VERSION."
}

function prepare_eap_source {
    download_and_unzip http://ftp.redhat.com/redhat/jboss/eap/$EAP_VERSION/en/source/$SRC_FILE
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src
    xml_delete_test_dependencies
    xml_clean eap

    cd $BUILD_HOME

    MVN=$BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src/mvnw
}

function prepare_core_source {
    download_and_unzip http://ftp.redhat.com/redhat/jboss/eap/$EAP_VERSION/en/source/jboss-eap-$EAP_VERSION-core-src.zip
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-core-src
    xml_delete_test_dependencies
    xml_clean core
    
    CORE_VERSION=$(xmlstarlet sel --template --value-of "/_:project/_:version" pom.xml)
    log "Core version: $CORE_VERSION"

    cd $BUILD_HOME

    MVN=$BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-core-src/mvnw
}

function build_core {
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-core-src
    maven_build testbom,core-feature-pack/galleon-feature-pack,core-feature-pack/galleon-common,core-feature-pack/common
    cd $BUILD_HOME
    log "Build done for Core $CORE_VERSION"
}

function build_eap {
    cd $BUILD_HOME/work/jboss-eap-$EAP_SHORT_VERSION-src
    if [ -d dist ]
    then
        maven_build "client/shade,dist"
    else
        # version 8.0 does not have a dist directory
        maven_build "client/shade,ee-dist"
        mv ee-dist dist
    fi
    cd $BUILD_HOME
    log "Build done for EAP $EAP_VERSION"
}

function maven_build {
    maven_exec "clean install" $1 
}

function maven_exec {
    settings=$BUILD_HOME/src/settings.xml
    mvn_options="--no-transfer-progress --settings $settings -Dquickly -Dmaven.test.skip -Drelease=true -Dversion.org.wildfly.core=$CORE_VERSION"
    if [ -n "$2" ]
    then
        msg="Maven $1 for $2"
        mvn_command="$MVN $1 --projects $2 --also-make $mvn_options"
    else
        msg="Maven $1 from root"
        mvn_command="$MVN $1 $mvn_options"
    fi

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
}

function is_supported_version {
    set +e
    supported_versions=$(get_supported_versions)
    supported_version=$(echo "$supported_versions," | grep -E "$1,")
    if [ -z $supported_version ]
    then
        failed "Version $1 is not supported. Supported versions are $supported_versions"
    fi
    set -e
}
function get_supported_versions {
    grep 'versions' src/jboss-eap-8.properties | sed -e "s/versions=//g"
}
function get_default_version {
    echo $(get_supported_versions) | sed s/,/\\n/g | tac | sed -n '1p'
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

function xml_delete_test_dependencies {
    for file in `find . -name pom.xml`; do
        xml_delete $file "/_:project/_:dependencies/_:dependency[_:scope='test']"
    done
}
function xml_delete {
    # echo xml_delete $*
    params=("$@")
    nb_params=$#
    xpath="${params[$nb_params-1]}" # last parameter

    for ((i=0; i<$#-1; i++)); do
        file=${params[$i]}
        mv $file .tmp.xml
        xmlstarlet ed --delete $xpath .tmp.xml > $file
        rm .tmp.xml
    done
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
    log $1
    echo ""
    failed "Build failed. You may have a look at the work/build.log file, maybe you'll find the reason why it failed."
}
