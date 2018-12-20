# frozen_string_literal: true

KafkaCommand::Engine.routes.draw do
  root 'clusters#index'
  get '/error', to: 'application#error'

  resources :clusters, only: [:index, :show] do
    resources :brokers, only: [:index, :show]
    resources :topics, id: /([^\/])+?/, format: /html|json/
    resources :consumer_groups, only: [:index, :show], id: /([^\/])+?/, format: /html|json/
  end
end
