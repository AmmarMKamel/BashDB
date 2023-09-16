#!/bin/bash

# Setting PS3 to a suitable prompt
PS3="Enter choice: "

# Define a global variable to hold the path to the databases directory
DATABASES_DIRECTORY="$HOME/databases"

# Define a global variable to hold absolute path of the directory containing this script
SCRIPTS_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import functions
source "$SCRIPTS_DIRECTORY/dbFunctions.sh"
source "$SCRIPTS_DIRECTORY/tableMenu.sh"
source "$SCRIPTS_DIRECTORY/tableOperations.sh"
source "$SCRIPTS_DIRECTORY/insertion.sh"
source "$SCRIPTS_DIRECTORY/selection.sh"
source "$SCRIPTS_DIRECTORY/deletion.sh"
source "$SCRIPTS_DIRECTORY/update.sh"

# Main menu implementation
while true; do
	echo "--------------------------Main Menu--------------------------"
	COLUMNS=1
	select choice in "Create Database" "List Databases" "Connect To Databases" "Drop Database" "Exit"; do
		case $REPLY in
            1) create_database ;;
            2) list_databases ;;
            3) connect_database ;;
            4) drop_database ;;
            5) exit ;;
		    *) echo "Invalid choice" ;;
		esac
		break
	done
done
