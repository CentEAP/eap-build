#!/bin/bash

full_version=$1
version=${full_version%%.*}
if [ "x$version" == "x" ] 
then
    version=8
fi

if [ "$version" == "$full_version" ] 
then
  # Omit the input as it is a major version
  source build-eap$version.sh
else
  source build-eap$version.sh $full_version
fi
