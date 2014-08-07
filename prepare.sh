#!/bin/bash
EAP_VERSION=6.3.0
EAP_SHORT_VERSION=6.3

unzip -q -d work download/jboss-eap-$EAP_VERSION-src.zip
unzip -q -d work download/jboss-eap-$EAP_VERSION-maven-repository.zip

shopt -s expand_aliases
case "`uname`" in
    Darwin*)
		command -v gsed >/dev/null 2>&1 || { echo -e "Hey, gsed is required on MacOS X. Aborting. \nTry 'brew install gnu-sed to fix it.'" >&2; exit 1; }
		alias sed='gsed'
		;;
esac

function remove_redhat_suffix {
	sed -i '/\<version.'$1'>/{s/.redhat-[0-9]//}' work/jboss-eap-6.2-src/pom.xml
}
sed -i '/\<version.org.jacorb>/{s/2.3.2.redhat-[0-9]/2.3.2-jbossorg-5/}' work/jboss-eap-6.2-src/pom.xml
remove_redhat_suffix org.projectodd.stilts
remove_redhat_suffix org.jboss.scandex
remove_redhat_suffix org.slf4j

mv work work-done

mkdir work
unzip -q -d work download/jboss-eap-$EAP_VERSION-src.zip
unzip -q -d work download/jboss-eap-$EAP_VERSION-maven-repository.zip
diff -abru work/jboss-eap-$EAP_SHORT_VERSION-src/pom.xml work-done/jboss-eap-$EAP_SHORT_VERSION-src/pom.xml > src/jboss-eap-$EAP_VERSION.patch

# on MacOS X
md5 -r download/jboss-eap-$EAP_VERSION-src.zip | sed 's/ /  /' > src/jboss-eap-$EAP_VERSION-src.zip.md5
md5 -r download/jboss-eap-$EAP_VERSION-maven-repository.zip | sed 's/ /  /' > src/jboss-eap-$EAP_VERSION-maven-repository.zip.md5
