class CsvUpload < ApplicationRecord
  has_one_attached :file
  has_one_attached :processed_file
end