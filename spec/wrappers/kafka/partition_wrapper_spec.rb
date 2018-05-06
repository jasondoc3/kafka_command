require 'app/wrappers/kafka/client_wrapper'

RSpec.describe Kafka::PartitionWrapper do
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  let(:partition) do
    Kafka::ClientWrapper
      .new(brokers: ['localhost:9092'])
      .cluster
      .topics
      .find { |t| t.name == topic_name }
      .partitions
      .sample
  end

  before { create_topic(topic_name) }
  after  { delete_topic(topic_name) }

  describe '#new' do
    it 'contains a reference to a topic wrapper' do
      expect(partition.topic).to be_an_instance_of(Kafka::TopicWrapper)
    end
  end

  describe '#highwater_mark_offset' do
    let(:num_messages) { 2 }

    before do
      num_messages.times { deliver_message('test', topic: topic_name) }
    end

    it 'retrieves the latest offset' do
      expect(partition.highwater_mark_offset).to eq(num_messages)
    end
  end

  describe '#as_json' do
    let(:expected_json) do
      {
        isr: partition.isr,
        leader: partition.leader,
        id: partition.partition_id,
        highwater_mark_offset: partition.highwater_mark_offset
      }.to_json
    end

    it 'equals the expected json' do
      expect(partition.as_json.to_json).to eq(expected_json)
    end
  end

  context 'forwarding' do
    let(:partition_metadata) do
      partition.instance_variable_get(:@partition_metadata)
    end

    describe '#isr' do
      it 'forwards isr to the partition metadata' do
        expect(partition_metadata).to receive(:isr)
        partition.isr
      end

      it 'returns the isr' do
        expect(partition.isr).to be_an_instance_of(Array)
        expect(partition.isr.first).to be_an_instance_of(Integer)
      end
    end

    describe '#leader' do
      it 'forwards leader to the partition metadata' do
        expect(partition_metadata).to receive(:leader)
        partition.leader
      end

      it 'returns the leader broker' do
        expect(partition.leader).to be_an_instance_of(Integer)
      end
    end

    describe '#partition_id' do
      it 'forwards leader to the partition metadata' do
        expect(partition_metadata).to receive(:leader)
        partition.leader
      end

      it 'returns the partition id' do
        expect(partition.partition_id).to be > -1
      end
    end

    describe '#replicas' do
      it 'forwards replicas to the partition metadata' do
        expect(partition_metadata).to receive(:replicas)
        partition.replicas
      end

      it 'returns the replica node ids' do
        expect(partition.replicas).to be_an_instance_of(Array)
        expect(partition.replicas.first).to be_an_instance_of(Integer)
      end
    end
  end
end
