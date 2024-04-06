#!/bin/bash

set -e

source src/functions-common.sh
source src/functions-8.sh

check_commands wget unzip patch javac grep curl xmlstarlet tac
set_version $1

make_directory -f work
make_directory download
make_directory dist

prepare_eap_source
prepare_core_source
build_core
build_eap

save_result
