require 'rails_helper'

RSpec.describe Cluster do
  let(:cluster_name) { 'test_cluster' }
  let(:broker)       { build(:broker) }
  let(:cluster)      { create(:cluster, name: cluster_name, brokers: [broker]) }

  describe '#client' do
    it 'creates and returns a Kafka::ClientWrapper' do
      expect(Kafka::ClientWrapper)
        .to receive(:new)
        .with(
          hash_including(
            brokers: [broker.host],
            client_id: cluster_name
          )
        ).and_call_original

      expect(cluster.client).to be_an_instance_of(Kafka::ClientWrapper)
    end
  end

  describe '#topics' do
    it 'calls ClusterWrapper#topics' do
      expect_any_instance_of(Kafka::ClusterWrapper).to receive(:refresh!).at_least(:once)
      expect_any_instance_of(Kafka::ClusterWrapper).to receive(:topics).once
      cluster.topics
    end
  end

  describe '#groups' do
    it 'calls Clusterwrapper#groups' do
      expect_any_instance_of(Kafka::ClusterWrapper).to receive(:refresh!).at_least(:once)
      expect_any_instance_of(Kafka::ClusterWrapper).to receive(:groups).once
      cluster.groups
    end
  end

  describe '#create_topic' do
    let(:topic_name) { 'test_topic' }
    let(:kwargs) do
      { replication_factor: 1, num_partitions: 1 }
    end

    it 'calls ClientWrapper#create_topic' do
      expect_any_instance_of(Kafka::ClientWrapper).to receive(:create_topic).with(topic_name, **kwargs)
      cluster.create_topic(topic_name, **kwargs)
    end
  end

  describe '#init_brokers' do
    before { allow_any_instance_of(Broker).to receive(:set_broker_id) }

    it 'initializes broker objects with hosts' do
      cluster.init_brokers('localhost:9093,localhost:9094')
      expect(cluster.brokers.map(&:host)).to include('localhost:9093')
      expect(cluster.brokers.map(&:host)).to include('localhost:9094')
      expect(cluster.reload.brokers.count).to eq(1)
    end
  end
end
