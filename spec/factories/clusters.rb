FactoryBot.define do
  factory :cluster, class: KafkaCommand::Cluster do
    name { 'test_cluster' }
    version { '1.0.0' }
    description { 'Test Cluster' }
    seed_brokers { ['localhost:9092'] }
  end

  factory :cluster_without_broker, class: KafkaCommand::Cluster do
    name { 'test_cluster' }
    version { '1.0.0' }
    description { 'Test Cluster' }
  end

  initialize_with do
    new(
      name: name,
      description: description,
      seed_brokers: seed_brokers,
      version: version
    )
  end
end
