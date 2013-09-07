1. Remove some -redhat-n suffixes
     
    Some RedHat patched artefacts are not provided in the local Maven repository (Maven plug-in + artefacts for unsupported feature). We have to remove the suffixe in order to download the nearest public version.

2. Prepare the patch

        cd work/jboss-*-src
        mvn clean
        rm -rf local-repo-eap
        mv work work-done
        #
        cd ../..
        unzip -q -d work download/jboss-eap-6.1.1-src.zip
        unzip -q -d work download/jboss-eap-6.1.1-maven-repository.zip
        diff -abru work work-done > src/jboss-eap-$EAP_VERSION.patch
