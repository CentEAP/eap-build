FROM centos
MAINTAINER Marco Bazzani
RUN yum update -y
RUN yum install -y wget python python-requests easy_install unzip
WORKDIR /tmp
RUN wget https://gist.githubusercontent.com/visik7/a61109129c04f5b48022/raw/145406c8fd3889a701b446ba9b1e573c502fa92c/runme.py
RUN wget http://www.crummy.com/software/BeautifulSoup/bs4/download/4.3/beautifulsoup4-4.3.2.tar.gz
RUN tar -xvf beautifulsoup4-4.3.2.tar.gz 
WORKDIR /tmp/beautifulsoup4-4.3.2
RUN python setup.py install
WORKDIR /tmp
RUN python runme.py -u uzdnqfle@sharklasers.com -p AAsdf1234 -U http://download.oracle.com/otn/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm
RUN yum -y localinstall jdk-7u80-linux-x64.rpm
WORKDIR /opt
RUN wget https://github.com/visik7/eap-build/releases/download/6.4.5/jboss-eap-6.4.zip
RUN unzip jboss-eap-6.4.zip
RUN ln -s jboss-eap-6.4 jboss
WORKDIR /opt/jboss/bin
RUN /opt/jboss/bin/add-user.sh -u admin -p Eap2015!
WORKDIR /opt/jboss
EXPOSE 9990 8009 
ENTRYPOINT ["./bin/standalone.sh"]
CMD ["-c", "standalone-full-ha.xml"]

