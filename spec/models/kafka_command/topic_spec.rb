# frozen_string_literal: true

RSpec.describe KafkaCommand::Topic do
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  let(:num_partitions) { 5 }
  let(:replication_factor) { 1 }
  let(:topic_creation_kwargs) do
    {
      num_partitions: num_partitions, replication_factor: replication_factor
    }
  end

  let(:topic) do
    KafkaCommand::Cluster.all.first.topics.find { |t| t.name == topic_name }
  end

  before { create_topic(topic_name, **topic_creation_kwargs) }

  describe '#new' do
    it 'initializes Kafka::Topic with name, replication_factor, and partitions' do
      expect(topic.name).to eq(topic_name)
      expect(topic.replication_factor).to eq(1)
      expect(topic.partitions.count).to eq(5)
      expect(topic.partitions.first).to be_an_instance_of(KafkaCommand::Partition)
    end
  end

  describe '#destroy' do
    it 'deletes the topic' do
      topic.destroy
      expect(topic_exists?(topic_name)).to eq(false)
    end
  end

  describe '#set_partitions!' do
    describe 'api not supported' do
      before do
        allow_any_instance_of(KafkaCommand::Client).to receive(:supports_api?).and_return(false)
      end

      it 'raises' do
        expect do
          topic.set_partitions!(num_partitions + 1)
        end.to raise_error(KafkaCommand::UnsupportedApiError)
      end
    end

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

  describe '#set_configs!' do
    context 'max message bytes' do
      describe 'greater than 0' do
        let(:max_message_bytes) { 1024 }

        it 'works' do
          topic.set_configs!(max_message_bytes: max_message_bytes)
          expect(topic.max_message_bytes).to eq(max_message_bytes)
        end
      end

      describe 'is 0' do
        let(:max_message_bytes) { 0 }

        it 'works' do
          topic.set_configs!(max_message_bytes: max_message_bytes)
          expect(topic.max_message_bytes).to eq(max_message_bytes)
        end
      end

      describe 'less than 0' do
        let(:max_message_bytes) { -1 }

        it 'errors' do
          expect { topic.set_configs!(max_message_bytes: max_message_bytes) }.to raise_error(Kafka::InvalidRequest)
        end
      end
    end

    context 'retention ms' do
      describe 'greater than 0' do
        let(:retention_ms) { 102400000 }

        it 'works' do
          topic.set_configs!(retention_ms: retention_ms)
          expect(topic.retention_ms).to eq(retention_ms)
        end
      end

      describe 'equal to 0' do
        let(:retention_ms) { 0 }

        it 'works' do
          topic.set_configs!(retention_ms: retention_ms)
          expect(topic.retention_ms).to eq(retention_ms)
        end
      end

      describe 'less than 0' do
        let(:retention_ms) { -1 }

        it 'works' do
          topic.set_configs!(retention_ms: retention_ms)
          expect(topic.retention_ms).to eq(retention_ms)
        end
      end
    end

    context 'retention bytes' do
      describe 'greater than 0' do
        let(:retention_bytes) { 102400000 }

        it 'works' do
          topic.set_configs!(retention_bytes: retention_bytes)
          expect(topic.retention_bytes).to eq(retention_bytes)
        end
      end

      describe 'equal to 0' do
        let(:retention_bytes) { 0 }

        it 'works' do
          topic.set_configs!(retention_bytes: retention_bytes)
          expect(topic.retention_bytes).to eq(retention_bytes)
        end
      end

      describe 'less than 0' do
        let(:retention_bytes) { -1 }

        it 'works' do
          topic.set_configs!(retention_bytes: retention_bytes)
          expect(topic.retention_bytes).to eq(retention_bytes)
        end
      end
    end
  end

  describe '#refresh!' do
    it 'reloads the topic metadata' do
      create_partitions_for(topic_name, num_partitions: num_partitions + 1)
      topic.refresh!
      expect(topic.partitions.count).to eq(num_partitions + 1)
    end
  end

  describe '#offset_for' do
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

    context 'including the config' do
      let(:expected_json) do
        {
          name: topic_name,
          replication_factor: replication_factor,
          partitions: partition_json,
          config: {
            max_message_bytes: described_class::DEFAULT_MAX_MESSAGE_BYTES,
            retention_ms: described_class::DEFAULT_RETENTION_MS,
            retention_bytes: described_class::DEFAULT_RETENTION_BYTES
          },
        }.to_json
      end

      it 'equals the expected payload' do
        expect(topic.as_json(include_config: true).to_json).to eq(expected_json)
      end
    end

    context 'not including the config' do
      let(:expected_json) do
        {
          name: topic_name,
          replication_factor: replication_factor,
          partitions: partition_json
        }.to_json
      end

      it 'equals the expected payload' do
        expect(topic.as_json.to_json).to eq(expected_json)
      end
    end
  end

  describe '#brokers_spread' do
    let(:broker_doubles) do
      [
        double(:broker),
        double(:broker),
        double(:broker),
        double(:broker),
        double(:broker)
      ]
    end

    before do
      allow(topic).to receive(:replication_factor).and_return(replication_factor_double)
      allow_any_instance_of(KafkaCommand::Client).to receive(:brokers).and_return(broker_doubles)
    end

    context '100%' do
      let(:replication_factor_double) { broker_doubles.count }

      it 'returns 100' do
        expect(topic.brokers_spread).to eq(100)
      end
    end

    context 'less than 20%' do
      let(:replication_factor_double) { 1 }

      it 'returns 20' do
        expect(topic.brokers_spread).to eq(20)
      end
    end
  end

  describe '#groups' do
    let(:group_id_1) { "test-group-#{SecureRandom.hex(12)}" }

    context 'group consuming' do
      it 'returns a list containing the group' do
        run_consumer_group(topic_name, group_id_1) do
          expect(topic.groups.map(&:group_id)).to include(group_id_1)
        end
      end
    end

    context 'group not consuming' do
      it 'returns a list not containing the group' do
        run_consumer_group(topic_name, group_id_1)
        expect(topic.groups.map(&:group_id)).to_not include(group_id_1)
      end
    end
  end

  describe '#consumer_offset_topic?' do
    context 'when consumer offset topic' do
      let(:consumer_offset_topic) { described_class::CONSUMER_OFFSET_TOPIC }

      before do
        allow(topic).to receive(:name).and_return(consumer_offset_topic)
      end

      it 'returns true' do
        expect(topic.consumer_offset_topic?).to eq(true)
      end
    end

    context 'normal topic' do
      it 'returns false' do
        expect(topic.consumer_offset_topic?).to eq(false)
      end
    end
  end
end
