Rails.application.routes.draw do

  # JSON Rest API
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :clusters, except: [:update, :new, :edit] do
        resources :brokers, only: [:index, :show]
        resources :topics, except: [:new, :edit]
        resources :consumer_groups, only: [:index, :show]
      end
    end
  end
end
