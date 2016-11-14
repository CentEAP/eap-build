#!/bin/bash

set -e
source src/functions-common.sh
source src/functions-7.sh

check_commands wget unzip patch which javac grep curl xmlstarlet
set_version $1

make_directory -f work
make_directory download
make_directory dist

prepare_eap_source
prepare_core_source
build_core
build_eap

save_result

