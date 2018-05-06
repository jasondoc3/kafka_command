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
      before { create_topic(topic_name) }
      after  { delete_topic(topic_name) }

      it 'initializes topics' do
        expect(cluster_wrapper.topics).to_not be_empty
        expect(cluster_wrapper.topics.first).to be_an_instance_of(Kafka::TopicWrapper)
        expect(cluster_wrapper.topics.map(&:name)).to include(topic_name)
      end
    end
  end

  describe '#refresh!' do
    let!(:cluster_wrapper) { described_class.new(client.cluster) }
    before { create_topic(topic_name) }
    after  { delete_topic(topic_name) }

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

    context 'with topics' do
      let(:metadata) { cluster_wrapper.fetch_metadata }
      before { create_topic(topic_name) }
      after  { delete_topic(topic_name) }

      it 'contains topic and partition metadata' do
        expect(metadata.topics).to_not be_empty
        expect(metadata.topics.sample).to be_an_instance_of(Kafka::Protocol::MetadataResponse::TopicMetadata)
        expect(metadata.topics.sample.partitions.first).to be_an_instance_of(Kafka::Protocol::MetadataResponse::PartitionMetadata)
      end
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
        before { create_topic(topic_name) }

        it 'deletes the topic' do
          expect(topic_exists?(topic_name)).to eq(true)
          cluster_wrapper.delete_topic(topic_name, **delete_topic_kwargs)
          expect(topic_exists?(topic_name)).to eq(false)
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
        before { create_topic(topic_name, num_partitions: 1) }
        after  { delete_topic(topic_name) }

        it 'changes the number of partitions' do
          expect(partitions_for(topic_name)).to eq(1)
          cluster_wrapper.create_partitions_for(topic_name, **create_partitions_kwargs)
          expect(partitions_for(topic_name)).to eq(5)
        end
      end
    end

    describe '#resolve_offset' do
      let(:partition_id) { 0 }

      it 'forwards resolve_offset to the Kafka::Cluster' do
        expect(cluster_wrapper.cluster).to receive(:resolve_offset).with(topic_name, partition_id, :latest)
        cluster_wrapper.resolve_offset(topic_name, partition_id, :latest)
      end

      context 'retrieving offsets 'do
        before { create_topic(topic_name) }
        after  { delete_topic(topic_name) }

        it 'returns the offset' do
          offset = cluster_wrapper.resolve_offset(topic_name, partition_id, :latest)
          expect(offset).to eq(0)

          deliver_message('test', topic: topic_name, partition: partition_id)
          offset = cluster_wrapper.resolve_offset(topic_name, partition_id, :latest)
          expect(offset).to eq(1)
        end
      end
    end
  end
end
