FactoryBot.define do
  factory :broker do
    host 'localhost:9092'
    sequence(:kafka_broker_id) { |n| n }
    association :cluster, factory: :cluster
  end
end
