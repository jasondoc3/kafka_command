# frozen_string_literal: true

require 'app/models/kafka_command/cluster'
require 'app/models/kafka_command/partition'

RSpec.describe KafkaCommand::Partition do
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  subject do
    KafkaCommand::Cluster.all.first.topics.find { |t| t.name == topic_name }.partitions.sample
  end

  before { create_topic(topic_name) }
  after  { delete_topic(topic_name) }

  describe '#new' do
    it 'contains a reference to a topic wrapper' do
      expect(subject.topic).to be_an_instance_of(KafkaCommand::Topic)
    end
  end

  describe '#highwater_mark_offset' do
    let(:num_messages) { 2 }

    before do
      num_messages.times { deliver_message('test', topic: topic_name) }
    end

    it 'retrieves the latest offset' do
      expect(subject.highwater_mark_offset).to eq(num_messages)
    end
  end

  describe '#as_json' do
    let(:expected_json) do
      {
        isr: subject.isr,
        leader: subject.leader,
        id: subject.partition_id,
        highwater_mark_offset: subject.highwater_mark_offset
      }.to_json
    end

    it 'equals the expected json' do
      expect(subject.as_json.to_json).to eq(expected_json)
    end
  end

  context 'forwarding' do
    let(:partition_metadata) do
      subject.instance_variable_get(:@partition_metadata)
    end

    describe '#isr' do
      it 'forwards isr to the partition metadata' do
        expect(partition_metadata).to receive(:isr)
        subject.isr
      end

      it 'returns the isr' do
        expect(subject.isr).to be_an_instance_of(Array)
        expect(subject.isr.first).to be_an_instance_of(Integer)
      end
    end

    describe '#leader' do
      it 'forwards leader to the partition metadata' do
        expect(partition_metadata).to receive(:leader)
        subject.leader
      end

      it 'returns the leader broker' do
        expect(subject.leader).to be_an_instance_of(Integer)
      end
    end

    describe '#partition_id' do
      it 'forwards leader to the partition metadata' do
        expect(partition_metadata).to receive(:leader)
        subject.leader
      end

      it 'returns the partition id' do
        expect(subject.partition_id).to be > -1
      end
    end

    describe '#replicas' do
      it 'forwards replicas to the partition metadata' do
        expect(partition_metadata).to receive(:replicas)
        subject.replicas
      end

      it 'returns the replica node ids' do
        expect(subject.replicas).to be_an_instance_of(Array)
        expect(subject.replicas.first).to be_an_instance_of(Integer)
      end
    end
  end
end
