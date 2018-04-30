require 'fast_helper'
require 'securerandom'
require 'kafka'
require 'config/initializers/kafka'
require 'app/wrappers/kafka/cluster_wrapper'

RSpec.describe Kafka::ClusterWrapper do
  let(:brokers)         { ['localhost:9092'] }
  let(:topic_name)      { "test-#{SecureRandom.hex(12)}" }
  let(:client)          { Kafka.new(seed_brokers: brokers) }
  let(:cluster_wrapper) { described_class.new(client.cluster) }

  describe '#new' do
    it 'wraps a Kafka::Cluster' do
      expect(cluster_wrapper.cluster).to be_an_instance_of(Kafka::Cluster)
    end

    it 'initializes brokers' do
      expect(cluster_wrapper.brokers).to_not be_empty
      expect(cluster_wrapper.brokers.count).to eq(1)
      expect(cluster_wrapper.brokers.first).to be_an_instance_of(Kafka::BrokerWrapper)
      expect(cluster_wrapper.brokers.first.host).to eq('localhost')
      expect(cluster_wrapper.brokers.first.port).to eq(9092)
    end

    context 'topics' do
      before { client.create_topic(topic_name) }
      after { client.delete_topic(topic_name) }

      it 'initializes topics' do
        expect(cluster_wrapper.topics).to_not be_empty
        expect(cluster_wrapper.topics.first).to be_an_instance_of(Kafka::TopicWrapper)
        expect(cluster_wrapper.topics.map(&:name)).to include(topic_name)
      end
    end
  end

  describe '#refresh!' do
    let!(:cluster_wrapper) { described_class.new(client.cluster) }
    before { client.create_topic(topic_name) }
    after  { client.delete_topic(topic_name) }

    it 'refreshes topic information' do
      expect(cluster_wrapper.topics.map(&:name)).to_not include(topic_name)
      cluster_wrapper.refresh!
      expect(cluster_wrapper.topics).to_not be_empty
      expect(cluster_wrapper.topics.map(&:name)).to include(topic_name)
    end
  end

  describe '#fetch_metadata' do
    let!(:cluster_wrapper) { described_class.new(client.cluster) }

    it 'calls fetch metadata on a Kafka::Broker' do
      expect_any_instance_of(Kafka::Broker).to receive(:fetch_metadata)
      cluster_wrapper.fetch_metadata
    end

    it 'returns a Kafka::Protocol::MetadataResponse' do
      expect(cluster_wrapper.fetch_metadata).to be_an_instance_of(Kafka::Protocol::MetadataResponse)
    end
  end

  context 'forwarding' do
    describe '#delete_topic' do
      let(:delete_topic_kwargs) do
        { timeout: 30 }
      end

      it 'forwards delete_topic to the Kafka::Cluster' do
        expect(cluster_wrapper.cluster).to receive(:delete_topic).with(topic_name, **delete_topic_kwargs)
        cluster_wrapper.delete_topic(topic_name, **delete_topic_kwargs)
      end

      context 'deletion' do
        before { client.create_topic(topic_name) }

        it 'deletes the topic' do
          expect(client.topics).to include(topic_name)
          cluster_wrapper.delete_topic(topic_name, **delete_topic_kwargs)
          expect(client.topics).to_not include(topic_name)
        end
      end
    end

    describe '#create_partitions_for' do
      let(:create_partitions_kwargs) do
        { num_partitions: 5, timeout: 30 }
      end

      it 'forwards create_partitions_for to the Kafka::Cluster' do
        expect(cluster_wrapper.cluster).to receive(:create_partitions_for).with(topic_name, **create_partitions_kwargs)
        cluster_wrapper.create_partitions_for(topic_name, **create_partitions_kwargs)
      end

      context 'altering partitions' do
        before { client.create_topic(topic_name, num_partitions: 1) }
        after { client.delete_topic(topic_name) }

        it 'changes the number of partitions' do
          topic = cluster_wrapper.fetch_metadata.topics.find { |t| t.topic_name == topic_name }
          expect(topic.partitions.count).to eq(1)
          cluster_wrapper.create_partitions_for(topic_name, **create_partitions_kwargs)
          topic = cluster_wrapper.fetch_metadata.topics.find { |t| t.topic_name == topic_name }
          expect(topic.partitions.count).to eq(5)
        end
      end
    end
  end
end
