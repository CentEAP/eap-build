#!/bin/bash

set -e
source src/functions-common.sh
source src/functions-6.sh

check_commands wget unzip patch javac grep curl
set_version $1

make_directory -f work
make_directory download
make_directory dist

download_and_unzip https://ftp.redhat.com/redhat/jboss/eap/$EAP_VERSION/en/source/$SRC_FILE
patch_files
maven_build

save_result

