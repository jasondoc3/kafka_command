Rails.application.routes.draw do
  mount KafkaCommand::Engine, at: '/'
end
