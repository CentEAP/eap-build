#!/bin/bash

source src/functions.sh

check_commands wget unzip patch javac
set_version $1
make_directory -f work
make_directory download
make_directory dist
download_and_unzip ftp://ftp.redhat.com/redhat/jbeap/$EAP_VERSION/en/source/$SRC_FILE
download_and_unzip http://maven.repository.redhat.com/techpreview/eap6/$EAP_VERSION/$MVN_FILE
patch_files
set_repository_url
maven_build
save_result

