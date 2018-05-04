require 'support/kafka_helper'
require 'app/wrappers/kafka/client_wrapper'

RSpec.describe Kafka::TopicWrapper do
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  let(:num_partitions) { 5 }
  let(:replication_factor) { 1 }
  let(:topic_creation_kwargs) do
    {
      num_partitions: num_partitions,
      replication_factor: replication_factor
    }
  end

  let(:topic) do
    Kafka::ClientWrapper
      .new(brokers: ['localhost:9092'])
      .cluster
      .topics
      .find { |t| t.name == topic_name }
  end

  before { create_topic(topic_name, **topic_creation_kwargs) }

  describe '#new' do
    after { delete_topic(topic_name) }

    it 'initializes Kafka::TopicWrapper with name, replication_factor, and partitions' do
      expect(topic.name).to eq(topic_name)
      expect(topic.replication_factor).to eq(1)
      expect(topic.partitions.count).to eq(5)
      expect(topic.partitions.first).to be_an_instance_of(Kafka::PartitionWrapper)
    end
  end

  describe '#destroy' do
    it 'deletes the topic' do
      topic.destroy
      expect(topic_exists?(topic_name)).to eq(false)
    end
  end

  describe '#set_partitions!' do
    after { delete_topic(topic_name) }

    describe 'num_partitions > current num_partitions' do
      it 'increases partitions' do
        topic.set_partitions!(num_partitions + 1)
        expect(topic.partitions.count).to eq(num_partitions + 1)
        expect(partitions_for(topic_name)).to eq(num_partitions + 1)
      end
    end

    describe 'num_partitions == current num_partitions' do
      it 'raises an error and stays the same' do
        expect { topic.set_partitions!(num_partitions) }.to raise_error(Kafka::InvalidPartitions)
        expect(topic.partitions.count).to eq(num_partitions)
        expect(partitions_for(topic_name)).to eq(num_partitions)
      end
    end

    describe 'num_partitions < current num_partitions' do
      it 'raises an error and stays the same' do
        expect { topic.set_partitions!(num_partitions - 1) }.to raise_error(Kafka::InvalidPartitions)
        expect(topic.partitions.count).to eq(num_partitions)
        expect(partitions_for(topic_name)).to eq(num_partitions)
      end
    end
  end

  describe '#refresh!' do
    after { delete_topic(topic_name) }

    it 'reloads the topic metadata' do
      create_partitions_for(topic_name, num_partitions: num_partitions + 1)
      topic.refresh!
      expect(topic.partitions.count).to eq(num_partitions + 1)
    end
  end

  describe '#offset_for' do
    after { delete_topic(topic_name) }
    let(:partition) { double(partition_id: 0) }
    let(:offset) { topic.offset_for(partition) }

    describe 'no messsages' do
      it 'returns 0' do
        expect(offset).to eq(0)
      end
    end

    describe 'messages' do
      let(:num_messages) { 2 }
      before do
        num_messages.times { deliver_message('test', topic: topic_name, partition: partition.partition_id) }
      end

      it 'returns the latest offset' do
        expect(offset).to eq(num_messages)
      end
    end
  end

  describe '#as_json' do
    let(:partition_json) { topic.partitions.sort_by(&:partition_id).map(&:as_json) }
    let(:expected_json) do
      {
        name: topic_name,
        replication_factor: replication_factor,
        partitions: partition_json
      }.to_json
    end

    after { delete_topic(topic_name) }

    it 'equals the expected payload' do
      expect(topic.as_json.to_json).to eq(expected_json)
    end
  end
end
