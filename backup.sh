#!/usr/bin/bash

#VARIABLES

LOG_FILE="/var/log/backup.log"
REMOTE_NAME="Remote"  # Change this to your rclone remote name if different
REMOTE_DIR="Backup"     # Change this to your desired folder in Google Drive
BACKUP_LIMIT=5  # Number of recent backups to keep
restore_dir="Restored_Backups"
BOLD="\e[1m"
RED="\e[31m"
BLUE="\E[34m"
Clear="\e[0m"
GREEN="\e[32m"

# Check if rclone is installed, if not install it
if ! command -v rclone &> /dev/null; then
	echo -e "\nRclone is not installed. Installing now..."
	sudo apt update && sudo apt install -y rclone
	echo -e "\nPlease configure rclone by running: rclone config"
	exit 1
fi


#update function
Update(){
	echo -e "\nManaging backup retention..."

	backups=($(ls -t "$backup_dest"/backup_*.tar.gz 2>/dev/null))

	if (( ${#backups[@]} > BACKUP_LIMIT )); then
		old_backups=("${backups[@]:$BACKUP_LIMIT}") # Keep only the most recent BACKUP_LIMIT
			for old_backup in "${old_backups[@]}"; do
				echo -e "\n${GREEN}Deleting old backup:${clear} $old_backup"
				rm -f "$old_backup"
			done
	fi
}


#Backup function
backup() {

	echo -e "\nEnter the backup destination directory (leave empty for default: /home/$USER/Backup):"
	read backup_dest
	backup_dest=${backup_dest:-"/home/$USER/Backup"}

	# Ensure the backup destination exists with proper permissions
	sudo mkdir -p  "$backup_dest"
	sudo mkdir -p  "$restore_dir"
	sudo chmod 777 "$backup_dest"
	sudo chmod 777 "$restore_dir"


	echo -e "\nEnter the files or directories to back up (separated by space):"
	read -a FILES

       	# Check if files exist before proceeding
	  for file in "${FILES[@]}"; do
	   	 if [[ ! -e "$file" ]]; then
		   	 echo -e "\n${RED}Error: File or directory '$file' not found. Skipping...${Clear}"
		   	 return
	   	 fi
   	 done

   	 timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
	 
   	 backup_file="$backup_dest/backup_$timestamp.tar.gz"

   	 tar -czf "$backup_file" -C "$(dirname "${FILES[0]}")" "${FILES[@]##*/}"


   	 if [[ $? -eq 0 ]]; then
		 echo -e "\n${GREEN}Backup successfully created at $backup_file${Clear}"
	  	 echo "$backup_file at $timestamp" | sudo tee -a "$LOG_FILE"

	   	 echo -e "\nUploading to Google Drive..."

	   	 rclone copy "$backup_dest" "$REMOTE_NAME:$REMOTE_DIR" -P

	   	 if [[ $? -eq 0 ]]; then
		   	 echo -e "\n${GREEN}Backup uploaded successfully to Google Drive in $REMOTE_DIR${Clear}"
	   	 else
		   	 echo -e "\n${RED}Upload failed. Please check your rclone configuration.${Clear}"
	   	 fi
   	 else
	   	 echo -e "\n${RED}An error occurred during backup.${Clear}"
   	 fi
   	 Update
}


#list maker function
list_backups() {
	echo -e "\nAvailable backups:"
	cat "$LOG_FILE"
}


#restoration function
Restore() {
	echo -e "\nEnter the backup name or keyword to restore:"
	read name

	    # Find the backup from Google Drive and download it
   	 echo -e "\nDownloading backup from Google Drive..."

   	 rclone copy "$REMOTE_NAME:$REMOTE_DIR/$name" "$backup_dest" -P

   	 if [[ $? -ne 0 ]]; then
		 echo -e "\n${RED}Error: Failed to download backup from Google Drive.${Clear}"
	  	 return
	 fi
	 backup_file="$backup_dest/$name"
	 if [[ ! -f "$backup_file" ]]; then
		 echo -e "\nError: No matching backup found."
	   	 return
   	 fi
	
	 tar -xzf "$backup_file" -C "$restore_dir"
	 rm -f "$backup_file"
	 echo -e "\n${GREEN}Restored files from $backup_file to $restore_dir successfully.${Clear}"
}


CRON_JOB="* * 1 * * backup.sh"

(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -


#MENU

echo "--------------------------------------------------"
echo -e "${BOLD}${BLUE}       AUTOMATED BACKUP AND RECOVERY TOOL${Clear}"
echo "--------------------------------------------------"
while true; do
	echo -e "Choose an option:"
	echo -e "\n1- Backup\n2- List\n3- Restore\n4- Exit"
	echo "--------------------------------------------------"

	read -r num;

	case "$num" in
		1)
			backup
			;;

		2)
			list_backups
			;;

		3)
			Restore
			;;

		4)
			echo -e "${BOLD}${BLUE}Exiting${Clear}"
			echo "--------------------------------------------------"
			exit 1
			;;


		*)
			echo -e "\n${RED}INVALID OPTION${Clear}"
			;;
	esac
done



