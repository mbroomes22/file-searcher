# Your Code Starts Here

require 'csv'
require 'fuzzy_match'

class MatchUsers
    def initialize(csv_file, match_types, output_file)
        @csv_file = csv_file
        @match_types = match_types
        @output_file = output_file
        @row_combo_values = {}
        @user_id_counter = 1
        @final_csv_rows = []
    end

    def group_and_write
        if read_and_group_data
            write_grouped_data
            puts "Grouped data written to #{@output_file}."
        end
    end

    private

    def sort_header_combos(arrays)
        # sorts the header arrays so that each array has a unique header combo match_type. ie. [[Phone1, Email],[Phone2, Email]], not [[Phone1, Phone2], [Email]]
        arrays.reduce([[]]) do |product, array|
          product.flat_map { |prefix| array.map { |item| prefix + [item] } }
        end
    end

    def match_types_to_headers(row)
        # finds all header keys that match the given match_type param.
        header_combos = @match_types.map do |type|
            FuzzyMatch.new(row.headers).find_all(type)
        end
        header_type_combos = sort_header_combos(header_combos)
        header_type_combos
    end


    def read_and_group_data
        begin 
            CSV.foreach(@csv_file, headers: true).with_index do |row, row_idx|
                header_type_combos = match_types_to_headers(row)
                row_user_id = @user_id_counter
                
                # get every combo of values for the desired match_type(s)
                header_type_combo_values = header_type_combos.map do |combo| 
                    value_array_for_each_header_combo = []
                    combo.map do |type|
                        value_array_for_each_header_combo << row[type]
                    end
                    # turn array into string
                    # needs to account for nil values and not match with those
                    next if value_array_for_each_header_combo.include?(nil)
                        value_string = value_array_for_each_header_combo.join(';')
                end

                # remove nil values from array
                header_type_combo_values = header_type_combo_values.compact


                # save all combo values for a row under the same user_id
                @row_combo_values[row_idx] = {values: header_type_combo_values, user_id: row_user_id}

                # compare current row values to previous row values:
                # if the combo matches an existing combo value, assign the row the existing combo value's user_id. Then save all that row's combos under that user_id.
                header_type_combo_values.each do |curr_row_value|
                    @row_combo_values.values.each do |prev_row_values|
                        if prev_row_values[:values].include?(curr_row_value)
                            # if there IS a match update all row combos in row_combo_values table with match's user_id.
                            row_user_id = prev_row_values[:user_id]
                            # if there IS a match update all row combos in row_combo_values table with match's user_id
                            @row_combo_values[row_idx][:user_id] = row_user_id
                            break
                        end
                    end
                end
                
                    # update row user_id to match's user_id and save in final_csv_rows array
                    row['user_id'] = row_user_id
                    @final_csv_rows << row.to_hash
                    @user_id_counter += 1
            end
            return true
        rescue Errno::ENOENT
            puts "Error: CSV file #{@csv_file} not found."
        end
    end

    def write_grouped_data
        CSV.open(@output_file, "w") do |csv|
            csv << @final_csv_rows.first.keys
            @final_csv_rows.each do |row|
                csv << row.values
            end
        end
    end
end

# upload csv & params from command line:

# param_array = ARGV
# csv_file_name = param_array.pop

# csv_file = csv_file_name
# match_types = param_array
# output_file = "matched_users_#{param_array.join('_')}.csv"

# grouper = MatchUsers.new(csv_file, match_types, output_file)
# grouper.group_and_write




# attach processed csv to CsvUpload record
# csv_upload.processed_file.attach(io: File.open(output_csv_path), filename: "processed_#{csv_upload.file.filename}")
# File.delete(output_csv_path)
# csv_upload.update()
# rescue => e
#     csv_upload.update(status: 'failed', error_message: e.message)
# end
