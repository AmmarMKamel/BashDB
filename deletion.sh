#!/bin/bash

# Function to delete rows from a table
function delete_from_table() {
	echo "-------------------'$dbname' - Delete Row(s)------------------"
	# Check if there are tables in the current database
	if [ -z "$(ls -A $DATABASES_DIRECTORY/$dbname)" ]; then
		echo "No tables found in the current database."
		return
	fi

	read -p "Enter the name of the table to delete from: " table_name

	# Check if the table exists
	if [ -f "$DATABASES_DIRECTORY/$dbname/$table_name.csv" ]; then
		# Get the column names and data types
		columns=$(head -n 1 "$DATABASES_DIRECTORY/$dbname/$table_name.csv")
		IFS=',' read -ra columns_array <<< "$columns"

		# Display the column names and data types
		echo "Table '$table_name':"
		for column in "${columns_array[@]}"; do
		    # Extract the column name and data type
		    IFS=':' read -ra column_info <<< "$column"
		    column_name="${column_info[0]}"
		    data_type="${column_info[1]}"

		    echo "- $column_name ($data_type)"
		done

		# Check if there are rows in the table
		row_count=$(wc -l < "$DATABASES_DIRECTORY/$dbname/$table_name.csv")
		if [ $row_count -le 1 ]; then
		    echo "The table '$table_name' is empty."
		    return 0
		else
		    echo "The table '$table_name' has $(($row_count-1)) row(s)."
		fi

		# Prompt user for deletion criteria
        read -p "Do you want to filter rows based on a specific column value? [y/n]: " filter_choice

		# Check if user wants to filter rows
        if [ "$filter_choice" = "y" ] || [ "$filter_choice" = "Y" ]; then
            # Prompt user for column name to filter by
            while true; do
                read -p "Enter the name of the column to filter by: " criteria_column

				# Check if column exists in table
				column_found=false
				for column in "${columns_array[@]}"; do 
					# Extract the column name from the column string.
					IFS=':' read -ra column_info <<< "$column"
					column_name="${column_info[0]}"

					# Remove any suffixes from the column name (e.g., "(PK)")
					column_name=${column_name%% *}

					# Check if this is the criteria column.
					if [ "$column_name" = "$criteria_column" ]; then 
						column_found=true 
						break 
					fi 
				done

				if [ "$column_found" = true ]; then 
					break 
				else 
					echo "Column '$criteria_column' does not exist in table '$table_name'."
				fi 
			done

			# Prompt user for value to filter by
			read -p "Enter the value to filter by: " criteria_value

			# Get the index of the criteria column
			criteria_index=0
			for column in "${columns_array[@]}"; do 
				# Extract the column name from the column string.
				IFS=':' read -ra column_info <<< "$column"
				column_name="${column_info[0]}"

				# Remove any suffixes from the column name (e.g., "(PK)")
				column_name=${column_name%% *}

				# Check if this is the criteria column.
				if [ "$column_name" = "$criteria_column" ]; then 
				    break 
				fi 

				((criteria_index++))
			done

			# Create a temporary file
			temp_file=$(mktemp)

			# Write the column names and data types to the temporary file
			echo $columns > "$temp_file"

			deleted_rows=0

			# Read the table, excluding rows that match the criteria
			while IFS= read -r line; do 
				# Save the current IFS value.
				old_ifs=$IFS

				# Set IFS to its default value.
				IFS=$' \t\n'

				# Extract all values from the row.
				IFS=',' read -ra row_values <<< "$line"

				# Extract the value of the criteria column from the row.
				row_value="${row_values[$criteria_index]}"

				# Restore the original IFS value after using cut.
				IFS=$old_ifs

				# Check if the row value matches the criteria value.
				if [ "$row_value" != "$criteria_value" ]; then 
                    echo $line >> "$temp_file"
                else
                    ((deleted_rows++))
                fi 
			done < <(tail -n +2 "$DATABASES_DIRECTORY/$dbname/$table_name.csv")

			# Replace the original file with the temporary file
			mv "$temp_file" "$DATABASES_DIRECTORY/$dbname/$table_name.csv"
		
			if [ $deleted_rows -eq 0 ]; then
                echo "No rows found matching criteria '$criteria_column=$criteria_value'."
            else
                echo "$deleted_rows row(s) deleted successfully."
            fi
        else
            # Delete all rows in the table by truncating the file after the first line (column names and data types)
            sed -i '2,$d' "$DATABASES_DIRECTORY/$dbname/$table_name.csv"
            echo "All rows deleted successfully."
        fi
    else 
        echo "Table '$table_name' does not exist."
    fi 
}