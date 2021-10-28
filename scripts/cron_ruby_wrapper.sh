#!/bin/bash

export rubyenv=/home/pepe/.rvm/environments/default

. $rubyenv 
cd /home/pepe/GEMS/${1}
export LC_ALL="en_US.utf8"

ruby ${2} ${3} ${4} ${5} ${6}

 
exit
for testing run 
env - `cat /home/pepe/bin/cron_ruby_wrapper.sh | tail -n 6` /bin/bash

HOME=/home/pepe
LOGNAME=pepe
PATH=/usr/bin:/bin
LANG=en_US.UTF-8
SHELL=/bin/sh
PWD=/home/pepe




