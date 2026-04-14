Rails.application.routes.draw do
  namespace :api do
    resources :articles, only: [ :index, :show ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # All non-API routes serve the React SPA shell
  root "pages#index"
  get "*path", to: "pages#index", constraints: ->(req) { !req.path.start_with?("/api", "/assets", "/up") }
end
