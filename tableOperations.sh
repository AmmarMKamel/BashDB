#!/bin/bash

# Function to create a new table
function create_table() {
	echo "-------------------'$dbname' - Create Table------------------"

	# Validate table name
    while true; do
        read -p "Enter the name of the new table: " table_name

        if [[ "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
            break
        else
            echo "Invalid table name. Table names should be alphanumeric and start with a letter."
			return
        fi
    done

  	# Check if the table already exists
	if [ -f "$DATABASES_DIRECTORY/$dbname/$table_name.csv" ]; then
		echo "Table '$table_name' already exists."
	else
		# Prompt user for the number of columns to add
        while true; do
            read -p "Enter the number of columns to add: " num_columns

            if [[ $num_columns =~ ^[0-9]+$ ]]; then
                if [ $num_columns -ne 0 ]; then
                    break
                else
                    echo "Invalid input. Number of columns cannot be zero."
                fi
            else
                echo "Invalid input. Please enter a positive integer."
            fi
        done

		# Prompt user for column names and data types
		columns=""
		primary_key=""
		declare -A column_names
		for ((i = 1; i <= num_columns; i++)); do
			while true; do
				read -p "Enter column $i name: " column_name

				if [[ $column_name =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
                    if [ ${column_names[$column_name]+_} ]; then 
						echo "Column '$column_name' already exists. Please enter a unique name."
					else 
						column_names["$column_name"]=1  # Add column name to the map.
						break 
					fi
                else
                    echo "Invalid column name. Column names should be alphanumeric and start with a letter."
                fi
            done

			while true; do
				read -p "Enter data type for column '$column_name' (int/string): " data_type
				if [ $data_type = "int" ] || [ $data_type = "string" ]; then
					break
				else
					echo "Invalid data type. Please enter 'int' or 'string'."
				fi
			done

			columns+="${column_name}:${data_type},"

			if [ -z "$primary_key" ]; then
				read -p "Is column '$column_name' the primary key? [y/n]: " primary_key_choice

				if [ "$primary_key_choice" = "y" ] || [ "$primary_key_choice" = "Y" ]; then
					primary_key="$column_name"
				fi
			fi
		done

		# Check if a primary key was specified by the user.
        if [ -z "$primary_key" ]; then 
            echo "Error: You must specify one column as the primary key."
            return 1
        fi

		# Remove trailing comma from columns string
		columns=${columns%,}

		# Create the table CSV file
		touch "$DATABASES_DIRECTORY/$dbname/$table_name.csv"

		# Write the column names and data types to the table file
		echo $columns > "$DATABASES_DIRECTORY/$dbname/$table_name.csv"

		# Add primary key indicator to the table file
		if [ -n $primary_key ]; then
			sed -i "1s/$primary_key/${primary_key} (PK)/" "$DATABASES_DIRECTORY/$dbname/$table_name.csv"
		fi
			echo "Table '$table_name' created successfully."
	fi
}

# Function to list all tables in the current database
function list_tables() {
	echo "-----------------------'$dbname' - Tables----------------------"
	# Check if there are tables in the current database
	if [ -z "$(ls -A $DATABASES_DIRECTORY/$dbname)" ]; then
		echo "No tables found in the current database."
		return
	fi

	for table in $DATABASES_DIRECTORY/$dbname/*; do
		# Extract the table name without the .csv extension
		table_name=$(basename "$table" .csv)
		echo "- $table_name"
	done
}

# Function to drop a table
function drop_table() {
	echo "----------------------'$dbname' - Drop Table---------------------"
	# Check if there are tables in the current database
	if [ -z "$(ls -A $DATABASES_DIRECTORY/$dbname)" ]; then
		echo "No tables found in the current database."
		return
	fi

	read -p "Enter the name of the table to drop: " table_name

	# Check if the table exists
	if [ -f "$DATABASES_DIRECTORY/$dbname/$table_name.csv" ]; then
		rm "$DATABASES_DIRECTORY/$dbname/$table_name.csv"
		echo "Table '$table_name' dropped successfully."
	else
		echo "Table '$table_name' does not exist."
	fi
}