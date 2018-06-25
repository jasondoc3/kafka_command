require 'app/wrappers/kafka/consumer_group_partition_wrapper'

RSpec.describe Kafka::ConsumerGroupPartitionWrapper do
  let(:group_id)     { "group-#{SecureRandom.hex(12)}" }
  let(:topic_name)   { "test-#{SecureRandom.hex(12)}" }
  let(:lag)          { 1 }
  let(:offset)       { 200 }
  let(:partition_id) { 1 }

  let(:consumer_group_partition_wrapper) do
    described_class.new(
      group_id: group_id,
      lag: lag,
      offset: offset,
      topic_name: topic_name,
      partition_id: partition_id
    )
  end

  describe '#new' do
    it 'creates a new Kafka::ConsumerGroupPartitionWrapper with attributes' do
      expect(consumer_group_partition_wrapper.lag).to eq(lag)
      expect(consumer_group_partition_wrapper.group_id).to eq(group_id)
      expect(consumer_group_partition_wrapper.topic_name).to eq(topic_name)
      expect(consumer_group_partition_wrapper.offset).to eq(offset)
      expect(consumer_group_partition_wrapper.partition_id).to eq(partition_id)
    end
  end

  describe '#as_json' do
    let(:expected_json) do
      {
        lag: lag,
        offset: offset,
        partition_id: partition_id
      }
    end

    it 'returns the expected payload' do
      expect(consumer_group_partition_wrapper.as_json).to eq(expected_json)
    end
  end
end
