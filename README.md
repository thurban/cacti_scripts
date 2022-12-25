# Cacti System Monitoring Script

The script provides a simple method to monitor the status of some critical system daemons ( database, http, cron ), memory, and disk space.  

The script sends out an email alert containing the specific issues. 

# CRON Schedule

*/2 * * * *  /bin/bash   /path/to/check_cacti_status.sh >> /tmp/log.txt
