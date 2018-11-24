FactoryBot.define do
  sequence(:host, 2) { |n| "localhost:909#{n}" }

  factory :broker, class: KafkaCommand::Broker do
    host { generate(:host) }
    sequence(:kafka_broker_id) { |n| n }
    association :cluster, factory: :cluster
  end
end
