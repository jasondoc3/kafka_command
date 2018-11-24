require 'rails_helper'

RSpec.describe KafkaCommand::Cluster do
  let(:cluster_name) { 'test_cluster' }
  let(:cluster)      { create(:cluster, name: cluster_name) }
  let(:topic_name)   { SecureRandom.hex(12) }

  describe '#client' do
    let(:broker) { cluster.brokers.first }

    it 'creates and returns a Kafka::ClientWrapper' do
      expect(KafkaCommand::ClientWrapper)
        .to receive(:new)
        .with(
          hash_including(
            brokers: [broker.host],
            client_id: cluster_name
          )
        ).and_call_original

      expect(cluster.client).to be_an_instance_of(KafkaCommand::ClientWrapper)
    end
  end

  after { delete_topic(topic_name) if topic_exists?(topic_name) }

  describe '#topics' do
    before { create_topic(topic_name) }

    it 'returns a list of topics' do
      expect(cluster.topics.first).to be_an_instance_of(KafkaCommand::TopicWrapper)
      expect(cluster.topics.map(&:name)).to include(topic_name)
    end
  end

  describe '#groups' do
    before { create_topic(topic_name) }
    let(:group_id) { SecureRandom.hex(12) }

    it 'returns a list of groups' do
      run_consumer_group(topic_name, group_id) do
        expect(cluster.groups.first).to be_an_instance_of(KafkaCommand::ConsumerGroupWrapper)
        expect(cluster.groups.map(&:group_id)).to include(group_id)
      end
    end
  end

  describe '#create_topic' do
    let(:topic_name) { 'test_topic' }
    let(:kwargs) do
      { replication_factor: 1, num_partitions: 1 }
    end

    it 'calls ClientWrapper#create_topic' do
      expect_any_instance_of(KafkaCommand::ClientWrapper).to receive(:create_topic).with(topic_name, **kwargs)
      cluster.create_topic(topic_name, **kwargs)
    end
  end

  describe '#init_brokers' do
    let(:cluster) { build(:cluster_without_broker, name: cluster_name) }

    it 'initializes broker objects with hosts' do
      cluster.init_brokers('localhost:9092')
      cluster.save!
      expect(cluster.brokers.map(&:host)).to include('localhost:9092')
      expect(cluster.reload.brokers.count).to eq(1)
    end
  end
end
