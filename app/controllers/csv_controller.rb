class CSVController
  def create
    @csv_upload = CsvUpload.new(csv_upload_params)

    if @csv_upload.save
      process_csv(@csv_upload) # start processing in the background
      render json: { id: @csv_upload.id,
                      message: ''}, status: :created
    else
      render json: @csv_upload.errors, status: :unprocessable_entity

    end
  end

  def show
    @csv_upload = CsvUpload.find(params[:id])
    processed_file_url = @csv_upload.processed_file.attached? ? url_for(@csv_upload.processed_file) : nil
    render jsom: { id: @csv_upload.id, 
                  status: @csv_upload.status,
                processed_file_url: processed_file_url}
  end

  private

  def csv_upload_params
    params.require(:csv_upload).permit(:file)
  end

  def process_csv(csv_upload)
    param_array = ARGV
    csv_file_name = param_array.pop

    csv_file = csv_file_name
    match_types = param_array
    output_file = "matched_users_#{param_array.join('_')}.csv"

    grouper = MatchUsers.new(csv_file, match_types, output_file)
    grouper.group_and_write
  end
end