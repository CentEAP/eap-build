#!/bin/bash
EAP_VERSION=6.2.0

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
remove_redhat_suffix org.jboss.byteman
remove_redhat_suffix org.apache.myfaces.core
remove_redhat_suffix org.slf4j

mv work work-done

unzip -q -d work download/jboss-eap-$EAP_VERSION-src.zip
unzip -q -d work download/jboss-eap-$EAP_VERSION-maven-repository.zip
diff -abru work work-done > src/jboss-eap-$EAP_VERSION.patch

md5 -r download/jboss-eap-$EAP_VERSION-src.zip > src/jboss-eap-$EAP_VERSION-src.zip.md5
md5 -r download/jboss-eap-$EAP_VERSION-maven-repository.zip > src/jboss-eap-$EAP_VERSION-maven-repository.zip.md5