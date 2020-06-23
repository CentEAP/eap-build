[![Build Status](https://travis-ci.org/hasalex/eap-build.svg)](https://travis-ci.org/hasalex/eap-build)

Building JBoss EAP, or something similar...

Why ?
=====
As I was not able to build JBoss EAP 6+, I've made a script who can download JBoss EAP 6+'s source code, patch the repository and launch the build with a JBoss Maven repository.

The result isn't exactly a JBoss EAP binary but something with a few differences.

How ?
=====
You can get the build script with git or wget.

With git
--------
If you want to run the script :

    git clone git://github.com/hasalex/eap-build.git
    cd eap-build
    ./build-eap7.sh

By default, it builds the latest EAP 7 update. You can build other versions by passing the number to the build :

    ./build-eap7.sh 7.0.3

For EAP 6 versions, you should use 

    ./build-eap6.sh

By default, it builds the latest EAP 6 update. You can build other versions by passing the number to the build :

    ./build-eap6.sh 6.4.7

Without git
-----------
If you don't want to use git, download the archive, unzip it and run the main script :

    wget https://github.com/hasalex/eap-build/archive/master.zip
    unzip master.zip
    cd eap-build-master
    ./build-eap7.sh

Versions
--------
The build-eap7.sh script supports 7.0.0->7.0.9, 7.1.0->7.1.4, 7.2.0->7.2.7, 7.3.0->7.3.1.

The build-eap6.sh script supports 6.1.1, 6.2.0->6.2.4, 6.3.0->6.3.3, 6.4.0->6.4.22.

Prerequisite and systems supported
==================================
The script is in bash. It should run on almost all bash-compatible systems. You have to install **wget**, **unzip**, **patch**, **java (JDK)**, **grep**, **curl** and **xmlstarlet** first.
