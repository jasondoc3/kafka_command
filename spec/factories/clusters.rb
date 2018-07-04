FactoryBot.define do
  factory :cluster do
    name 'test_cluster'
    version '1.0.0'
    description 'Test Cluster'

    trait(:with_broker) do
      before(:create) do |cluster|
        create(:broker, cluster: cluster)
      end
    end
  end
end
