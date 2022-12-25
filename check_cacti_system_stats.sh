#!/bin/bash
# Simple Cacti Check Scripts
# Checks for
#   SYSTEM STATS 
#       database/httpd/crond daemon Status
#       Free Memory
#
#
#########

#
alertemail="support@example.com"
#
cacti_log=/var/www/html/cacti/log/cacti.log
min_mem_free_perc=20
database_daemon=mariadb
webserver_daemon=httpd
cron_daemon=crond
alert_threshold=90

polling_failed=0
no_free_memory=0
database_failed=0
webserver_failed=0
crond_failed=0

## Get some defaults:
host=`hostname -f`
disk_list=`df |grep dev |grep -v tmpfs |grep -v udev| awk -F" " '{print $1}' | cut -d/ -f3`


## Memory check
free_mem_prec=`free | grep Mem | awk '{ printf("%.0f", $4/$2 * 100.0) }'`
if (($free_mem_prec < $min_mem_free_perc))
then
    no_free_memory=1
    echo "">> /tmp/mail.txt
    echo "Free Memory = ${free_mem_prec} %" >> /tmp/mail.txt
    echo "The system has low free memory. Please check" >> /tmp/mail.txt        
else
    no_free_memory=0
fi

## Polling Stats Check
last_stat=`grep "SYSTEM STATS" $cacti_log | awk '{print $1" "$2}' | sort -u | tail -n 1`
last_stats_seconds=`date -d "$last_stat" +"%s"`
current_seconds=`date +"%s"`
if ((($current_seconds - 1200) > $last_stats_seconds))
then
        polling_failed=1
    echo "">> /tmp/mail.txt
    echo "Cacti POLLING: FAILED/ERROR" >> /tmp/mail.txt
    echo "The Cacti polling is not working correctly. Please check" >> /tmp/mail.txt
else
        polling_failed=0
fi

## MySQL Check
database_status=`systemctl status $database_daemon | grep 'Active:' | grep running |wc -l`
if (($database_status == 0))
then
    database_failed=1
    echo "">> /tmp/mail.txt
    echo "Database Daemon: FAILED/ERROR" >> /tmp/mail.txt
    echo "The Database Daemon is not working correctly. Please check" >> /tmp/mail.txt
else
    database_failed=0
fi


## HTTP/Wevserver Check
webserver_status=`systemctl status $webserver_daemon | grep 'Active:' | grep running |wc -l`
if (($webserver_status == 0))
then
    webserver_failed=1
    echo "">> /tmp/mail.txt
    echo "WebServer Daemon: FAILED/ERROR" >> /tmp/mail.txt
    echo "The WebServer Daemon is not working correctly. Please check" >> /tmp/mail.txt
else
    webserver_failed=0
fi

## crond Check
crond_status=`systemctl status $cron_daemon | grep 'Active:' | grep running |wc -l`
if (($crond_status == 0))
then
    crond_failed=1
    echo "">> /tmp/mail.txt
    echo "CRON Daemon: FAILED/ERROR" >> /tmp/mail.txt
    echo "The Cron Daemon is not working correctly. Please check" >> /tmp/mail.txt
else
    crond_failed=0
fi



## Check Disk Space
i=0
for disk in $disk_list
do
    space_use=`df | grep $disk | awk -F" " '{print $5}' | cut -d% -f1`
    if [ "$space_use" -gt "$alert_threshold" ]
    then
        i=$((i + 1))
        over_threshold["$i"]="$disk"
    fi
done


if [ ${#over_threshold[*]} -gt 0 ]
then
    echo >>/tmp/mail.txt
    echo "">> /tmp/mail.txt
    echo "Disks with space problem with more than $alert_threshold% occupied space" >> /tmp/mail.txt
    echo "">> /tmp/mail.txt
    for disk in ${over_threshold[*]}
    do
        info_disk=(`df -h | grep ${disk} | awk -F" " '{print $6, $2, $3, $4, $5}'`)
        echo "- Mount point : ${info_disk[O]} - Total space : ${info_disk[1]} - Used space : ${info_disk[2]} - Free space : ${info_disk[3]} - Used space in percents : ${info_disk[4]}" >> /tmp/mail.txt ; echo "" >> /tmp/mail.txt
    done
fi

## Check if we need to send out an email alert
if test -f "/tmp/mail.txt"; 
then
    subject="ALERT: $host - Some Issues have been identified"
    cat /tmp/mail.txt |mail -s "$subject" $alertemail
    ## remove temp mail file
    rm -f /tmp/mail.txt
fi

