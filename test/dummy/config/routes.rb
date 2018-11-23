Rails.application.routes.draw do
  mount KafkaCommand::Engine, at: 'kafka_command'
end
