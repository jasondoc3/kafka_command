KafkCommand::Engine.routes.draw do
  root 'clusters#index'

  resources :clusters, except: [:update, :edit] do
    resources :brokers, only: [:index, :show]
    resources :topics, id: /([^\/])+?/, format: /html|json/
    resources :consumer_groups, only: [:index, :show], id: /([^\/])+?/, format: /html|json/
  end
end
