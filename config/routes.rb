Rails.application.routes.draw do
  resources :csv_uploads, only: [:create, :show]
end