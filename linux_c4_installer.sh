#!/bin/bash -x
#
# The linux centralized command and control center
# 
# Redundancy is key
#
# Using free and opensource software to build a command and control center capable 
# of standard system administration tasks such as logging, monitoring and 
# backups.

# requirements: (based on small business of less than 20 linux servers) 
# ubuntu 12.04
# 4 cores (lots of java)
# 8 Gb ram
# 40 Gb hdd (more needed depending on backup scheme)

# provides:
# dns/dhcp server:	dnsmasq
# web server: 		apache2
# scripting server: 	rundeck
# log manager: 		kibana
# orchestration: 	chef
# trending:		observium
# monitoring:		icinga
# ip tracking:		opennetadmin
# rack tracking:	rackmonkey

# for installation of elasticsearch, mongodb and graylog -- please see this github repo:
# https://github.com/vmanapat/graylog2installer/blob/master/install_graylog.sh

# must be run as root
	if [[ $EUID -ne 0 ]]; then
		echo "script must be run as root"
		exit
	fi

# check password env variable
	if [ -z $PASSWORD ]; then
		echo "You must set the PASSWORD variable to something for us to use as a default password"
		exit
	fi

# check ubuntu version
	{ lsb_release -a | grep "Ubuntu 12.10"; } || { echo "requires ubuntu 12.10"; exit; }

# update ubuntu
	apt-get -y update
	apt-get -y upgrade

# install helpful programs
	apt-get -y install vim git subversion gcc make libssl-dev build-essential apache2 php5 php5-mysql\
	php5-gmp php5-fpm
	apt-get -fy install

# set hostname
	HOSTNAME=c4

# set hostname in /etc/hosts
	IP=$(ip a | grep inet | grep eth0 | awk {'print $2'} | cut -d'/' -f1 )
	echo "$IP $HOSTNAME" >> /etc/hosts

# set non-interactive mysql password
	echo "mysql-server mysql-server/root_password password $PASSWORD" | sudo debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password $PASSWORD" | sudo debconf-set-selections

# set non-interactive postfix
	echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections	
	echo "postfix postfix/mailname string $HOSTNAME" | debconf-set-selections

# set non-interactive icinga 
	echo "icinga-common icinga/check_external_commands select false" | debconf-set-selections
	echo "icinga-cgi icinga/adminpassword-repeat string $PASSWORD" | debconf-set-selections
	echo "icinga-cgi icinga/adminpassword string $PASSWORD" | debconf-set-selections
	echo "icinga-cgi icinga/httpd select apache2" | debconf-set-selections

# make tmp source directory and opt installation directory
	export TMP=/root/linuxc4/source
	export C4=/opt
	mkdir -vp $TMP
	mkdir -vp $C4
	cd $TMP

# install ruby
	mkdir /tmp/ruby && cd /tmp/ruby
	curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.gz | tar xz
	cd ruby-2.0.0-p247
	./configure
	make
	make install
	gem install bundler --no-ri --no-rdoc

# name:		rundeck
# endpoint: 	http://localhost:4440
# user:pass: 	admin:admin
# help:		http://rundeck.org/1.3.2/RunDeck-Guide.html

	wget http://download.rundeck.org/deb/rundeck-1.6.1-1-GA.deb
	echo "deb http://www.duinsoft.nl/pkg debs all" >> /etc/apt/sources.list
	apt-key adv --keyserver keys.gnupg.net --recv-keys 5CB26B26
	apt-get -y update
	apt-get -y install update-sun-jre
	apt-get -y -f install
	dpkg -i rundeck-1.6.1-1-GA.deb
	service rundeckd start

# name:		chef
# endpoint:	https://localhost
# user:pass:	admin:admin
# help:		http://docs.opscode.com/
	
	# hostname MUST be set beforehand
	wget https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.8-1.ubuntu.12.04_amd64.deb
	dpkg -i chef-server_11.0.8-1.ubuntu.12.04_amd64.deb
	chef-server-ctl reconfigure
	chef-server-ctl test

# name:		dnsmasq
# endpoint:	no endpoint
# user:pass:	no user:pass
# help:		http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
# notes:	configure /etc/hosts

	apt-get -y install dnsmasq dnsmasq-utils dnsmasq-base
	service dnsmasq restart

# name:		icinga
# endpoint:	http://localhost
# user:pass:	icingaadmin:icingaadmin
# help:		http://docs.icinga.org/

	apt-get -y install mysql-server postfix
	apt-get -y install icinga*

# name:		elasticsearch
# endpoint:
# user:pass:
# help:		http://www.elasticsearch.org/guide/

	echo JAVA_HOME="/usr/bin/java" >> /root/.bash_profile
	export JAVA_HOME="/usr/bin/java"
	wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.0.deb
	dpkg -i elasticsearch-0.90.0.deb
	service elasticsearch start



# INCOMPLETE
# http://cookbook.logstash.net/recipes/rsyslog-agent/
# name:         logstash
# endpoint:	http://localhost:9292
# user:pass:
# help:		http://logstash.net/docs/1.2.1/tutorials/getting-started-simple
	mkdir -v /opt/logstash
	cd /opt/logstash
	wget http://logstash.objects.dreamhost.com/release/logstash-1.2.1-flatjar.jar
	wget http://logstash.net/docs/1.2.1/tutorials/10-minute-walkthrough/apache-parse.conf
	java -jar logstash-1.2.1-flatjar.jar agent -f apache-parse.conf &


# INCOMPLETE
# name:         kibana
# endpoint:	http://localhost:5601
# user:pass:
# help:		http://kibana.org/contact.html
	cd $TMP
	git clone --branch=kibana-ruby https://github.com/rashidkpc/Kibana.git
	cd Kibana
	bundle install
	ruby kibana.rb

# name:         observium
# endpoint:	http://localhost/observium
# user:pass:
# help:		http://www.observium.org/wiki/Documentation
	cd /var/www
	svn checkout http://www.observium.org/svn/observer/trunk/ observium

# name:         rackmonkey
# endpoint:
# user:pass:
# help:		https://flux.org.uk/projects/rackmonkey/doc/
	cd $TMP
	wget http://downloads.sourceforge.net/project/rackmonkey/rackmonkey/1.2.5/rackmonkey-1.2.5-1.tar.gz
	tar zxvf rackmonkey-1.2.5-1.tar.gz
	mv rackmonkey-1.2.5-1 rackmonkey
	mv rackmonkey /var/www/
	
# INCOMPLETE
# name:		opennetadmin
# endpoint:
# user:pass:
# help:		https://github.com/opennetadmin/ona/wiki/Install
	cd $TMP
	wget https://github.com/opennetadmin/ona/archive/ona-current.tar.gz
	tar zxvf ona-current.tar.gz
	
# cleanup
	cd /root
	rm -rf /$TMP
	chown -R www-data:www-data /var/www/
