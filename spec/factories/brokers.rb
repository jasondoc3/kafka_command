FactoryBot.define do
  factory :broker do
    host 'localhost:9092'
    kafka_broker_id 0
    association :cluster, factory: :cluster
  end
end
