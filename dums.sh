#!/bin/bash

################################################################################################################################
# This script will send notification to specified  emailid whenever the disk space exceed the threshold disk space value.      #
# Before sending email it takes care that it hasn't sent any email in past six hours.                                          #
# Create configuration file with name "dums.conf" to add custom threshold disk space and email recipients in following format  #
#                                                                                                                              #
# threshold_disk_space=<int value>                                                                                             #
# mailid=<user1@example.com>                                                                                                   #
# mailid=<user2@example.com>                                                                                                   #
#                                                                                                                              #
# There can be any number of mailid's in the config file, all of them will be notified with the email at appropriate condition #
################################################################################################################################


#default value of threshold
threshold_disk_space=80

#IP address of the machine
ip=$(hostname -I | awk '{print $1}')

#integer value of disk space occupied
current_disk_space=$(df / | grep / | awk '{ print $5}' | sed 's/%//g')

#current system time in seconds
current_system_time=$(date +%s)

#file which stores last mail sent timestamp
timestamp_file='last_sent_timestamp'

#file which stores configuration
config_file='dums.conf'

#array of mail ids
mailids=()

parse_configfile()
{
        if [[ -f $config_file && -s $config_file  ]] ; then
                while IFS== read -r key value; do
                        if [[ $key = 'mailid' ]] ; then
                                #append mailid's in array
                                mailids+=("$value")
                        elif [[ $key = 'threshold_disk_space' ]]; then
                                #overwriting threshold value 
                                threshold_disk_space=$value
                        fi
                done < $config_file
        fi
}

send_alertmail()
{
        #sends mail to all the mailid's mentioned in conf. file        
        for mailid in "${mailids[@]}" ; do
                echo "Your root partition remaining free space is critically low for $HOSTNAME whose IP is: $ip. 
                Used: $current_disk_space%" | mail -s "$HOSTNAME [$ip] Disk Space Alert" "$mailid"
        done
}

parse_configfile

if [[ "$current_disk_space" -gt "$threshold_disk_space" ]] ; then
        #if file is not empty
        if [[ -f $timestamp_file && -s $timestamp_file  ]] ; then
                line=$(tail -n 1 $timestamp_file)
                #21600 seconds are equivalent to 6hrs
                if [[ $((line + 21600)) -lt "$current_system_time" ]] ; then
                        echo "$current_system_time" > $timestamp_file
                        send_alertmail
                fi
        else
                echo "$current_system_time" > $timestamp_file
                send_alertmail
        fi
fi