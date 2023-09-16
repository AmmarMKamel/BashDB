#!/bin/bash

# Function to insert a row into a table
function insert_into_table() {
	echo "----------------------'$dbname' - Insert Row---------------------"
	# Check if there are tables in the current database
	if [ -z "$(ls -A $DATABASES_DIRECTORY/$dbname)" ]; then
		echo "No tables found in the current database."
		return
	fi

	read -p "Enter the name of the table to insert into: " table_name

	# Check if the table exists
	if [ -f "$DATABASES_DIRECTORY/$dbname/$table_name.csv" ]; then
		# Get the column names and data types
		columns=$(head -n 1 "$DATABASES_DIRECTORY/$dbname/$table_name.csv")
		IFS=',' read -ra columns_array <<< "$columns"

		# Initialize an array to store the values to insert
		values=()

		# Prompt user for values to insert
		for column in "${columns_array[@]}"; do
			# Extract the column name and data type
			IFS=':' read -ra column_info <<< "$column"
			column_name="${column_info[0]}"
			data_type="${column_info[1]}"

			# Check if the column is the primary key
			is_primary_key=false
			if [[ $column_name == *" (PK)" ]]; then
				is_primary_key=true
				column_name=${column_name%?????}
			fi

			# Prompt user for value to insert
			while true; do
				read -p "Enter value for column '$column_name' ($data_type): " value

				# Validate value based on data type
				if [ $data_type = "int" ]; then
					if [[ $value =~ ^-?[0-9]+$ ]]; then
						if [ "$is_primary_key" = true ] && [ $value -lt 0 ]; then
							echo "Invalid value. Please enter a positive integer."
						else
							break
						fi
					else
						echo "Invalid value. Please enter an integer."
					fi
				elif [ $data_type = "string" ]; then
					if [ -z "$value" ]; then
						echo "Invalid value. Please enter a non-empty string."
					else
						break
					fi
				fi
			done

			# Check if value is unique for primary key column
			if [ "$is_primary_key" = true ]; then
				# Get the index of the primary key column
				pk_index=$(echo $columns | grep -bo "$column_name" | grep -oE '[0-9]+')

				# Check if value already exists in primary key column
				if cut -d ',' -f $((pk_index+1)) "$DATABASES_DIRECTORY/$dbname/$table_name.csv" | grep -q "^$value$"; then
					echo "Error: Value '$value' already exists in primary key column '$column_name'."
					return 1
				fi
			fi

			# Add value to values array
			values+=("$value")
		done

		# Write values to table file
		echo "${values[*]}" | sed 's/ /,/g' >> "$DATABASES_DIRECTORY/$dbname/$table_name.csv"
		echo "Row inserted successfully."
	else
		echo "Table '$table_name' does not exist."
	fi
}