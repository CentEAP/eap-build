rm -rf build
mkdir build

wget ftp://ftp.redhat.com/redhat/jbeap/6.0.1/en/source/jboss-eap-6.0.1-src.zip
unzip -d build jboss-eap-6.0.1-src.zip
rm jboss-eap-6.0.1-src.zip

wget http://maven.repository.redhat.com/techpreview/eap6/6.0.1/jboss-eap-6.0.1-maven-repository.zip
unzip -d build jboss-eap-6.0.1-maven-repository.zip
rm jboss-eap-6.0.1-maven-repository.zip

cd build/jboss-eap-6.0.1-maven-repository/
patch -p 1 < ../../src/jboss-eap-6.0.1-maven-repository.patch
cd ../..
cp src/settings.xml build/jboss-eap-6.0-src/tools/maven/conf/

export EAP_REPO_URL=file://`pwd`/build/jboss-eap-6.0.1-maven-repository/
cd build/jboss-eap-6.0-src/
./build.sh

cp -R build/target/jboss-eap-6.0 ../

