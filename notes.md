1. Remove some -redhat-n suffixes
     
    Some RedHat patched artefacts are not provided in the local Maven repository (Maven plug-in + artefacts for unsupported feature). We have to remove the suffixe in order to download the nearest public version.

2. Prepare the patch

    EAP_VERSION=6.3.0
    #
    cd work/jboss-*-src
    mvn clean
    rm -rf local-repo-eap
    mv work work-done
    #
    cd ../..
    unzip -q -d work download/jboss-eap-$EAP_VERSION-src.zip
    unzip -q -d work download/jboss-eap-$EAP_VERSION-maven-repository.zip
    diff -abru work work-done > src/jboss-eap-$EAP_VERSION.patch
    #
    md5 -r download/jboss-eap-$EAP_VERSION-src.zip > src/jboss-eap-$EAP_VERSION-src.zip.md5
    md5 -r download/jboss-eap-$EAP_VERSION-maven-repository.zip > src/jboss-eap-$EAP_VERSION-maven-repository.zip.md5