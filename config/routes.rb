Rails.application.routes.draw do

  # JSON Rest API
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :clusters, except: [:update, :new, :edit]
    end
  end
end
