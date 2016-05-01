#!/bin/bash

source src/functions.sh

check_commands wget unzip patch javac grep curl
set_version $1
make_directory -f work
make_directory download
make_directory dist
download_and_unzip http://ftp.redhat.com/redhat/jbeap/$EAP_VERSION/en/source/$SRC_FILE
patch_files
build_core
maven_build
save_result
