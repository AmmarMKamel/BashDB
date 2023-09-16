#!/bin/bash

# Function to update rows in a table
function update_table() {
    echo "-------------------'$dbname' - Update Row(s)------------------"
    # Check if there are tables in the current database
    if [ -z "$(ls -A $DATABASES_DIRECTORY/$dbname)" ]; then
        echo "No tables found in the current database."
        return
    fi

    read -p "Enter the name of the table to update: " table_name

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

		# Prompt user for update criteria
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

            row_found=false
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
                if [ "$row_value" = "$criteria_value" ]; then 
                    row_found=true 
                    break
                fi 
            done < <(tail -n +2 "$DATABASES_DIRECTORY/$dbname/$table_name.csv")

            if [ "$row_found" = false ]; then 
                echo "No rows found matching criteria '$criteria_column=$criteria_value'."
                return 0
            fi

            pk_index=-1
            pk_value=""
            for i in "${!columns_array[@]}"; do 
              IFS=':' read -ra parts <<< "${columns_array[$i]}"
              if [[ "${parts[0]}" == *" (PK)" ]]; then
                pk_index=$i
                pk_value="${row_values[$pk_index]}"
                break
              fi
            done

            if [ $pk_index -eq -1 ]; then
              echo "Error: No primary key column found."
              return 1
            fi

            # Prompt user for primary key value if multiple rows match the criteria
            row_count=0
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
                if [ "$row_value" = "$criteria_value" ]; then 
                    ((row_count++))
                    if [ $row_count -gt 1 ]; then
                        break
                    fi
                fi 
            done < <(tail -n +2 "$DATABASES_DIRECTORY/$dbname/$table_name.csv")
			#set -x
            if [ $row_count -gt 1 ]; then
                read -p "Multiple rows found matching criteria '$criteria_column=$criteria_value'. Enter the primary key value of the row to update: " pk_value
            fi

            # Create a temporary file
            temp_file=$(mktemp)

            # Write the column names and data types to the temporary file
            echo $columns > "$temp_file"

            updated_rows=0
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

                # Check if the row value matches the criteria value and primary key value.
                if [ "$row_value" = "$criteria_value" ] && [ "${row_values[$pk_index]}" = "$pk_value" ]; then 
                    new_row=""
                    for i in "${!columns_array[@]}"; do 
                        column="${columns_array[$i]}"
                        old_value="${row_values[$i]}"

                        # Extract the column name and data type
                        IFS=':' read -ra column_info <<< "$column"
                        column_name="${column_info[0]}"
                        data_type="${column_info[1]}"

                        is_primary_key=false
                        if [[ $column_name == *" (PK)" ]]; then
                            is_primary_key=true
                            column_name=${column_name%?????}
                        fi

                        while true; do 
                            read -u 1 -d $'\n' -p "Enter new value for column '$column_name' ($data_type) [current: $old_value]: " new_value

                            if [ -z "$new_value" ]; then 
                                new_value="$old_value"
                                break 
                            fi 

                            # Validate new value based on data type
                            if [ $data_type = "int" ]; then 
                                if [[ $new_value =~ ^-?[0-9]+$ ]]; then 
                                    if [ "$is_primary_key" = true ] && [ $new_value -lt 0 ]; then 
                                        echo "Invalid value. Please enter a positive integer."
                                    else 
                                        break 
                                    fi 
                                else 
                                    echo "Invalid value. Please enter an integer."
                                fi 
                            elif [ $data_type = "string" ]; then 
                                break 
                            fi 
                        done 

                        # Check if new value is unique for primary key column
                        if [ "$is_primary_key" = true ] && [ "$new_value" != "$old_value" ]; then 
                            # Check if new value already exists in primary key column
                            if cut -d ',' -f $((pk_index+1)) "$DATABASES_DIRECTORY/$dbname/$table_name.csv" | grep -q "^$new_value$"; then 
                                echo "Error: Value '$new_value' already exists in primary key column '$column_name'."
                                return 1
                            fi 
                        fi 

                        new_row+="$new_value,"
                    done

                    new_row=${new_row%,}
                    echo $new_row >> "$temp_file"
                    ((updated_rows++))
                else 
                    echo $line >> "$temp_file"
                fi 
            done < <(tail -n +2 "$DATABASES_DIRECTORY/$dbname/$table_name.csv")
			# Replace the original file with the temporary file
            mv "$temp_file" "$DATABASES_DIRECTORY/$dbname/$table_name.csv"

            if [ $updated_rows -eq 0 ]; then
                echo "No rows found matching criteria '$criteria_column=$criteria_value' and primary key value '$pk_value'."
            else
                echo "$updated_rows row(s) updated successfully."
            fi
    else 
        echo "Table '$table_name' does not exist."
    fi 
}
#set +x