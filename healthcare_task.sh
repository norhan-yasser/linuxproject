#!/bin/bash

# Define the log file location

LOG_FILE="system_monitor.log"

# Function to check disk_usage

disk_usage() {
	
	THREESHOLD=80

DISk_USAGE=$( df / | grep / | awk '{print $5 }' | sed 's/%//')

 if [ $DISk_USAGE -gt $THREESHOLD ];
 then
         echo " WARNING DISK USAGE IS EXCEEEDE , CURRENT DISK USAGE IS $DISk_USAGE " | tee -a $LOG_FILE
 else
         echo " CURRENT DISK USGE IS $DISk_USAGE " | tee -a  $LOG_FILE
 fi
 
 disk_usage=$( df -h )
         echo "disk usage: $disk_usage"  | tee -a $LOG_FILE

}

# Function to check CPU usage
cpu_usage() {
    echo "Checking CPU Usage..."
    # 'top -bn1' runs top in batch mode for one iteration
    # 'grep "Cpu(s)"' filters the CPU usage line
    # 'awk' extracts and sums user and system CPU usage
    usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    # Print the CPU usage
    echo "CPU Usage: $usage%" | tee -a $LOG_FILE

}

# Function to check Memory usage
memory_usage() {
    echo "Checking Memory Usage..."
    # 'free -m' gives memory stats in MB
    # 'awk' extracts total, used, and available memory
    total_mem=$(free -m | awk 'NR==2{print $2}')
    used_mem=$(free -m | awk 'NR==2{print $3}')
    free_mem=$(free -m | awk 'NR==2{print $4}')

    # Print the Memory usage
    echo "Total Memory: ${total_mem}MB" | tee -a $LOG_FILE
    echo "Used Memory: ${used_mem}MB" | tee -a $LOG_FILE
    echo "Free Memory: ${free_mem}MB"  | tee -a $LOG_FILE

}


#function for pending_software

software_updates() {

	#check the updates
if [[ $(sudo apt-get -s upgrade) == "0 upgraded, 0 newly installed" ]]; then
    
	echo "No updates available" | tee -a $LOG_FILE
else

   # Share updates with users
   
    echo "Updates are available for the system. Please run 'sudo apt-get update && sudo apt-get upgrade' to install them." | tee -a $LOG_FILE

fi
         
}

network_status(){

local_ip=$(hostname -I | awk '{print $1}')
echo "Local IP Address: $local_ip" | tee -a $LOG_FILE


# Set a reliable host to ping (e.g., Google's DNS server)
HOST="8.8.8.8"

# Ping the host and check the result
ping -c 4 $HOST &> /dev/null

if [ $? -eq 0 ]; then
    echo "Network is up and connected." | tee -a $LOG_FILE
else
    echo "Network is down or not connected." | tee -a $LOG_FILE
fi

# Check internet speed using speedtest-cli
echo "Checking download and upload speeds..."

# Run speedtest and capture the output
speedtest-cli --simple | tee -a $LOG_FILE



}


#run the functions

echo "Daily check done at : $(date)" | tee  $LOG_FILE

disk_usage
cpu_usage
memory_usage
software_updates 
network_status








