linuxcccc
=========

_The linux centralized command and control center installation script_

Using free and opensource software to build a small business server capable
of standard system administration tasks such as logging, monitoring and
backups.

###requirements 
_(based on small business of less than 20 linux servers)_
* ubuntu 12.04
* 4 cores (lots of java)
* 8 Gb ram
* 40 Gb hdd (more needed depending on backup scheme)

###provides
* dns/dhcp server:      dnsmasq
* web server:           apache2, nginx 
* script server:        rundeck
* log store:            logstash/elasticsearch
* log manager:          kibana
* orchestration:        chef
* backup server:        rsync ;)
* trending:           	observium
* monitoring:		        icinga
* ip tracking:		      opennetadmin
* rack tracking:	      rackmonkey
