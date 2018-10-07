FactoryBot.define do
  factory :cluster do
    name { 'test_cluster' }
    version { '1.0.0' }
    description { 'Test Cluster' }

    before(:create) do |cluster|
      cluster.brokers = [build(:broker, cluster: cluster)] if cluster.brokers.none?
    end
  end

  factory :cluster_without_broker, class: Cluster do
    name { 'test_cluster' }
    version { '1.0.0' }
    description { 'Test Cluster' }
  end
end
