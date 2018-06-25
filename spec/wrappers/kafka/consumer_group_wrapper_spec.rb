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
end
