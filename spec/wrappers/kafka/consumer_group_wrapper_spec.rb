require 'app/wrappers/kafka/client_wrapper'

RSpec.describe Kafka::ConsumerGroupWrapper do
  let(:group_id) { "test-group-#{SecureRandom.hex(24)}" }
  let(:topic_name) { "test-topic-#{SecureRandom.hex(24)}" }
  let(:num_partitions) { 5 }
  let(:group) do
    Kafka::ClientWrapper
      .new(brokers: ['localhost:9092'])
      .cluster
      .groups
      .find { |g| g.group_id == group_id }
  end

  before { create_topic(topic_name, num_partitions: num_partitions) }
  after  { delete_topic(topic_name) }

  describe '#new' do
    describe 'running' do
      it 'initializes a stable Kafka::ConsumerGroupWrapper with group_id, members, and state' do
        run_consumer_group(topic_name, group_id) do
          expect(group.group_id).to eq(group_id)
          expect(group.members).to_not be_empty
          expect(group.members.sample).to be_an_instance_of(Kafka::GroupMemberWrapper)
          expect(group.state).to eq('Stable')
        end
      end
    end

    describe 'dormant' do
      before { run_consumer_group(topic_name, group_id) }

      it 'initializes an empty Kafka::ConsumerGroupWrapper with group_id, members, and state' do
        expect(group.group_id).to eq(group_id)
        expect(group.members).to be_empty
        expect(group.state).to eq('Empty')
      end
    end
  end

  describe '#refresh!' do
    it 'refreshes the group metadata' do
      run_consumer_group(topic_name, group_id) do
        expect(group.state).to eq('Stable')
        expect(group.members).to_not be_empty
      end

      group.refresh!
      expect(group.members).to be_empty
      expect(group.state).to eq('Empty')
    end
  end

  describe '#stable?' do
    describe 'running' do
      it 'returns true' do
        run_consumer_group(topic_name, group_id) do
          expect(group.stable?).to eq(true)
        end
      end
    end

    describe 'dormant' do
      before { run_consumer_group(topic_name, group_id) }

      it 'returns false' do
        expect(group.stable?).to eq(false)
      end
    end
  end

  describe '#stable?' do
    describe 'running' do
      it 'returns true' do
        run_consumer_group(topic_name, group_id) do
          expect(group.stable?).to eq(true)
        end
      end
    end

    describe 'dormant' do
      before { run_consumer_group(topic_name, group_id) }

      it 'returns false' do
        expect(group.stable?).to eq(false)
      end
    end
  end

  describe '#empty?' do
    describe 'running' do
      it 'returns false' do
        run_consumer_group(topic_name, group_id) do
          expect(group.empty?).to eq(false)
        end
      end
    end

    describe 'dormant' do
      before { run_consumer_group(topic_name, group_id) }

      it 'returns true' do
        expect(group.empty?).to eq(true)
      end
    end
  end

  describe '#partitions_for' do
    let(:num_partitions) { 3 }
    let(:partitions) { group.partitions_for(topic_name) }
    let(:total_lag)  { partitions.map(&:lag).compact.reduce(:+) }

    it 'returns ConsumerGroupPartitionWrappers' do
      run_consumer_group(topic_name, group_id) do
        expect(partitions.count).to eq(num_partitions)
        expect(partitions.sample).to be_an_instance_of(Kafka::ConsumerGroupPartitionWrapper)
        expect(partitions.sample.group_id).to eq(group_id)
        expect(partitions.sample.topic_name).to eq(topic_name)
      end
    end

    context 'some partitions no offsets' do
      before { run_consumer_group(topic_name, group_id) }

      it 'has "nil" lag' do
        expect(partitions.map(&:lag)).to include(nil)
      end
    end

    context 'lag' do
      let(:partition_0) do
        partitions.find { |p| p.partition_id == 0 }
      end

      let(:partition_1) do
        partitions.find { |p| p.partition_id == 1 }
      end

      let(:partition_2) do
        partitions.find { |p| p.partition_id == 2 }
      end

      before do
        deliver_message('test', topic: topic_name, partition: 0)
        deliver_message('test1', topic: topic_name,  partition: 1)
        deliver_message('test2', topic: topic_name , partition: 2)
        run_consumer_group(topic_name, group_id, num_messages_to_consume: 3)
      end

      describe 'no lag' do
        it 'has no lag' do
          expect(partition_0.lag).to eq(0)
          expect(partition_1.lag).to eq(0)
          expect(partition_2.lag).to eq(0)
        end
      end

      describe 'some lag' do
        before do
          2.times { deliver_message('test', topic: topic_name, partition: 0) }
          3.times { deliver_message('test1', topic: topic_name,  partition: 1) }
        end

        it 'has lag' do
          expect(total_lag).to eq(5)
          expect(partition_0.lag).to eq(2)
          expect(partition_1.lag).to eq(3)
          expect(partition_2.lag).to eq(0)
        end
      end
    end
  end

  describe '#consumed_topics' do
    context 'running' do
      it 'returns a list of topics' do
        run_consumer_group(topic_name, group_id) do
          expect(group.consumed_topics.map(&:name)).to include(topic_name)
        end
      end
    end

    context 'dormant' do
      before { run_consumer_group(topic_name, group_id) }

      it 'returns an empty list' do
        expect(group.consumed_topics).to be_empty
      end
    end
  end

  describe '#as_json' do
    let(:num_partitions) { 3 }
    let(:partitions) { group.partitions_for(topic_name) }


    before do
      deliver_message('test', topic: topic_name, partition: 0)
      deliver_message('test1', topic: topic_name,  partition: 1)
      deliver_message('test2', topic: topic_name , partition: 2)
      run_consumer_group(topic_name, group_id, num_messages_to_consume: 3)
      2.times { deliver_message('test', topic: topic_name, partition: 0) }
      3.times { deliver_message('test1', topic: topic_name,  partition: 1) }
    end

    context 'running' do
      let(:expected_json) do
        {
          group_id: group_id,
          topics: [
            {
              name: topic_name,
              partitions: partitions.map(&:as_json)
            }
          ],
          state: 'Stable'
        }
      end

      it 'returns the expected payload' do
        run_consumer_group(topic_name, group_id) do
          expect(group.as_json).to eq(expected_json)
        end
      end
    end

    context 'dormant' do
      let(:expected_json) do
        {
          group_id: group_id,
          topics: [],
          state: 'Empty'
        }
      end

      it 'returns the expected payload' do
        expect(group.as_json).to eq(expected_json)
      end
    end
  end
end
