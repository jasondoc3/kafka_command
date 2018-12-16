# frozen_string_literal: true

require 'app/models/kafka_command/consumer_group_partition'

RSpec.describe KafkaCommand::ConsumerGroupPartition do
  let(:group_id)     { "group-#{SecureRandom.hex(12)}" }
  let(:topic_name)   { "test-#{SecureRandom.hex(12)}" }
  let(:lag)          { 1 }
  let(:offset)       { 200 }
  let(:partition_id) { 1 }

  let(:consumer_group_partition_) do
    described_class.new(
      group_id: group_id,
      lag: lag,
      offset: offset,
      topic_name: topic_name,
      partition_id: partition_id
    )
  end

  describe '#new' do
    it 'creates a new Kafka::ConsumerGroupPartition with attributes' do
      expect(consumer_group_partition_.lag).to eq(lag)
      expect(consumer_group_partition_.group_id).to eq(group_id)
      expect(consumer_group_partition_.topic_name).to eq(topic_name)
      expect(consumer_group_partition_.offset).to eq(offset)
      expect(consumer_group_partition_.partition_id).to eq(partition_id)
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
      expect(consumer_group_partition_.as_json).to eq(expected_json)
    end
  end
end
