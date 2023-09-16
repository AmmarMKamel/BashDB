#!/bin/bash

# Function to handle database creation
function create_database() {
	echo "-----------------------Create Database-----------------------"
	read -p "Enter database name: " dbname

	# Database name validation
	if [[ $dbname =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
		# Check if the database exists
		if [ -d "$DATABASES_DIRECTORY/$dbname" ]; then
			echo "Database '$dbname' already exists."
		else
			# Create a new directory for the database
			mkdir -p "$DATABASES_DIRECTORY/$dbname"
			echo "Database '$dbname' created successfully."
		fi
	else
		echo "Invalid database name. Database names should be alphanumeric and start with a letter."
	fi
}

# Function to list existing databases
function list_databases() {
	echo "---------------------Available Databases---------------------"
	# Check if there are databases or not
	if [ -z "$(ls -A "$DATABASES_DIRECTORY")" ]; then
        echo "- No databases found."
	else
		for dbname in `ls -1 "$DATABASES_DIRECTORY"`; do
			echo "- ${dbname}"
		done
	fi
}

# Function to connect to one of the existing databases
function connect_database() {
	echo "---------------------Connect to Database---------------------"
	# Check if there are databases or not
	if [ -z "$(ls -A "$DATABASES_DIRECTORY")" ]; then
        echo "- No databases found."
		return
	fi

    read -p "Enter database name: " dbname
    
	# Check if the database exists
	if [ -d "$DATABASES_DIRECTORY/$dbname" ]; then
		echo "Connected to database '$dbname'."
		table_menu "$dbname"
	else
		echo "Database '$dbname' does not exist."
	fi
}

# Function to drop a database
function drop_database() {
	echo "------------------------Drop Database------------------------"
	# Check if there are databases or not
	if [ -z "$(ls -A "$DATABASES_DIRECTORY")" ]; then
        echo "- No databases found."
		return
	fi

    read -p "Enter database name: " dbname

	# Check if the database exists
	if [ -d "$DATABASES_DIRECTORY/$dbname" ]; then
		rm -r "$DATABASES_DIRECTORY/$dbname"
		echo "Database '$dbname' dropped successfully."
	else
		echo "Database '$dbname' does not exist."
	fi
}