Rails.application.routes.draw do
  root 'clusters#index'

  resources :clusters, except: [:update, :edit] do
    resources :brokers, only: [:index, :show]
    resources :topics, except: [:new, :edit]
    resources :consumer_groups, only: [:index, :show]
  end
end
