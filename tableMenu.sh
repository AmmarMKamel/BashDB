#!/bin/bash

# Function for the table menu
function table_menu() {
  typeset dbname=$1

  while true; do
		echo "-------------------'$dbname' - Database Menu-------------------"
		COLUMNS=1
		select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select from Table" "Delete from Table" "Update Table" "Back to Main Menu"; do
			case $REPLY in
			  1) create_table ;;
			  2) list_tables ;;
			  3) drop_table ;;
			  4) insert_into_table ;;
			  5) select_from_table ;;
			  6) delete_from_table ;;
			  7) update_table ;;
			  8) break 2 ;;
			  *) echo "Invalid choice. Please try again." ;;
			esac
			break
		done
  done
}