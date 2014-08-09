#!/bin/bash
rm -rf repository
mkdir repository
mv dist dist-old

sh build-eap.sh $1

rm -rf dist
rm -rf repository
mv dist-old dist
