# frozen_string_literal: true

RSpec.describe KafkaCommand::Client do
  let(:host)       { 'localhost' }
  let(:port)       { 9092 }
  let(:brokers)    { ["#{host}:#{port}"] }
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  let(:group_id)   { "test-#{SecureRandom.hex(12)}" }
  let(:client)     { kafka_client }

  after { delete_topic(topic_name) if topic_exists?(topic_name) }
  subject { described_class.new(brokers: brokers) }

  describe '#new' do
    it 'wraps a Kafka::Cluster' do
      expect(subject.cluster).to be_an_instance_of(Kafka::Cluster)
    end
  end

  describe '#brokers' do
    it 'initializes brokers' do
      expect(subject.brokers).to_not be_empty
      expect(subject.brokers.count).to eq(ENV['SEED_BROKERS'].split(',').count)
      expect(subject.brokers.first).to be_an_instance_of(KafkaCommand::Broker)
      expect(subject.brokers.first.host).to eq('localhost')
      expect(subject.brokers.map(&:port)).to include(9092)
    end
  end

  describe '#topics' do
    before { create_topic(topic_name) }

    it 'initializes topics' do
      expect(subject.topics).to_not be_empty
      expect(subject.topics.first).to be_an_instance_of(KafkaCommand::Topic)
      expect(subject.topics.map(&:name)).to include(topic_name)
    end
  end

  describe '#groups' do
    before do
      create_topic(topic_name)
      run_consumer_group(topic_name, group_id)
    end

    it 'initializes groups' do
      expect(subject.groups).to_not be_empty
      expect(subject.groups.first).to be_an_instance_of(KafkaCommand::ConsumerGroup)
      expect(subject.groups.map(&:group_id)).to include(group_id)
    end
  end

  describe '#refresh_topics!' do
    it 'refreshes topic information' do
      expect(subject.topics.map(&:name)).to_not include(topic_name)
      create_topic(topic_name)
      subject.refresh_topics!
      expect(subject.topics).to_not be_empty
      expect(subject.topics.map(&:name)).to include(topic_name)
    end
  end

  describe '#refresh_groups!' do
    before do
      subject.groups
      create_topic(topic_name)
      run_consumer_group(topic_name, group_id)
    end

    it 'refreshes group information' do
      expect(subject.groups.map(&:group_id)).to_not include(group_id)
      subject.refresh_groups!
      expect(subject.groups.map(&:group_id)).to include(group_id)
    end
  end

  describe '#refresh!' do
    it 'refreshes cluster information' do
      expect(subject).to receive(:refresh_topics!).once
      expect(subject).to receive(:refresh_brokers!).once
      expect(subject).to receive(:refresh_groups!).once
      subject.refresh!
    end
  end

  describe '#fetch_metadata' do
    it 'returns a Kafka::Protocol::MetadataResponse' do
      expect(subject.fetch_metadata).to be_an_instance_of(Kafka::Protocol::MetadataResponse)
    end

    context 'with topics' do
      let(:metadata) { subject.fetch_metadata }
      before { create_topic(topic_name) }

      it 'contains topic and partition metadata' do
        expect(metadata.topics).to_not be_empty
        expect(metadata.topics.sample).to be_an_instance_of(Kafka::Protocol::MetadataResponse::TopicMetadata)
        expect(metadata.topics.sample.partitions.first).to be_an_instance_of(Kafka::Protocol::MetadataResponse::PartitionMetadata)
      end
    end
  end

  describe '#find_topic' do
    context 'topic exists' do
      before { create_topic(topic_name) }

      it 'returns the topic' do
        expect(subject.find_topic(topic_name)).to be_an_instance_of(KafkaCommand::Topic)
        expect(subject.find_topic(topic_name).name).to eq(topic_name)
      end
    end

    context 'topic non-existent' do
      it 'returns nil' do
        expect(subject.find_topic(topic_name)).to be_nil
      end
    end
  end

  describe '#connect_to_broker' do
    let(:broker_id) { subject.brokers.first.node_id }

    it 'returns a KafkaCommand::Broker' do
      result = subject.connect_to_broker(
        host: host,
        port: port,
        broker_id: broker_id
      )

      expect(result).to be_an_instance_of(KafkaCommand::Broker)
      expect(result.port).to eq(port)
      expect(result.host).to eq(host)
      expect(result.node_id).to eq(broker_id)
    end
  end

  context 'forwarding' do
    describe '#broker_pool' do
      it 'forwards broker_pool to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:broker_pool)
        subject.broker_pool
      end

      it 'returns a Kafka::BrokerPool' do
        expect(subject.broker_pool).to be_an_instance_of(Kafka::BrokerPool)
      end
    end

    describe '#delete_topic' do
      let(:delete_topic_kwargs) do
        { timeout: 30 }
      end

      it 'forwards delete_topic to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:delete_topic).with(topic_name, **delete_topic_kwargs)
        subject.delete_topic(topic_name, **delete_topic_kwargs)
      end

      context 'deletion' do
        before { create_topic(topic_name) }

        it 'deletes the topic' do
          expect(topic_exists?(topic_name)).to eq(true)
          subject.delete_topic(topic_name, **delete_topic_kwargs)
          expect(topic_exists?(topic_name)).to eq(false)
        end
      end
    end

    describe '#alter_topic' do
      let(:retention_ms) { 1000000 }
      let(:retention_bytes) { 100000000 }
      let(:max_message_bytes) { 100000000 }
      let(:alter_topic_configs) do
        {
          'retention.ms' => retention_ms,
          'retention.bytes' => retention_bytes,
          'max.message.bytes' => max_message_bytes
        }
      end

      it 'forwards alter_topic to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:alter_topic).with(topic_name, alter_topic_configs)
        subject.alter_topic(topic_name, alter_topic_configs)
      end

      context 'altering the topic' do
        before { create_topic(topic_name) }

        it 'alters the configs' do
          subject.alter_topic(topic_name, alter_topic_configs)
          configs = subject.describe_topic(topic_name, alter_topic_configs.keys)
          expect(configs['max.message.bytes']).to eq(max_message_bytes.to_s)
          expect(configs['retention.bytes']).to eq(retention_bytes.to_s)
          expect(configs['retention.ms']).to eq(retention_ms.to_s)
        end
      end
    end

    describe '#describe_topic' do
      let(:describe_topic_configs) { KafkaCommand::Topic::TOPIC_CONFIGS }

      it 'forwards describe_topic to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:describe_topic).with(topic_name, describe_topic_configs)
        subject.describe_topic(topic_name, describe_topic_configs)
      end

      context 'describing the topic' do
        before { create_topic(topic_name) }

        it 'describes the topic' do
          config = subject.describe_topic(topic_name, describe_topic_configs)
          describe_topic_configs.each { |c| expect(config.key?(c)).to eq(true) }
        end
      end
    end

    describe '#create_partitions_for' do
      let(:create_partitions_kwargs) do
        { num_partitions: 5, timeout: 30 }
      end

      it 'forwards create_partitions_for to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:create_partitions_for).with(topic_name, **create_partitions_kwargs)
        subject.create_partitions_for(topic_name, **create_partitions_kwargs)
      end

      context 'altering partitions' do
        before { create_topic(topic_name, num_partitions: 1) }

        it 'changes the number of partitions' do
          expect(partitions_for(topic_name)).to eq(1)
          subject.create_partitions_for(topic_name, **create_partitions_kwargs)
          expect(partitions_for(topic_name)).to eq(5)
        end
      end
    end

    describe '#resolve_offset' do
      let(:partition_id) { 0 }

      it 'forwards resolve_offset to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:resolve_offset).with(topic_name, partition_id, :latest)
        subject.resolve_offset(topic_name, partition_id, :latest)
      end

      context 'retrieving offsets ' do
        before { create_topic(topic_name) }

        it 'returns the offset' do
          offset = subject.resolve_offset(topic_name, partition_id, :latest)
          expect(offset).to eq(0)

          deliver_message('test', topic: topic_name, partition: partition_id)
          offset = subject.resolve_offset(topic_name, partition_id, :latest)
          expect(offset).to eq(1)
        end
      end
    end

    describe '#resolve_offsets' do
      let(:num_partitions) { 2 }
      let(:partition_ids) { [0, 1] }

      it 'forwards resolve_offsets to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:resolve_offsets).with(topic_name, partition_ids, :latest)
        subject.resolve_offsets(topic_name, partition_ids, :latest)
      end

      context 'retrieving offsets ' do
        before { create_topic(topic_name, num_partitions: num_partitions) }

        it 'returns the offsets' do
          offsets = subject.resolve_offsets(topic_name, partition_ids, :latest)

          partition_ids.each do |partition_id|
            expect(offsets[partition_id]).to eq(0)

            deliver_message('test', topic: topic_name, partition: partition_id)
            offset = subject.resolve_offsets(topic_name, partition_ids, :latest)
            expect(offset[partition_id]).to eq(1)
          end
        end
      end
    end

    describe '#describe_group' do
      it 'forwards describe_group to the Kafka::Cluster' do
        expect(subject.cluster).to receive(:describe_group).with(group_id)
        subject.describe_group(group_id)
      end

      context 'describing' do
        before do
          create_topic(topic_name)
          run_consumer_group(topic_name, group_id)
        end

        it 'returns the group metadata' do
          expect(subject.describe_group(group_id)).to be_an_instance_of(Kafka::Protocol::DescribeGroupsResponse::Group)
          expect(subject.describe_group(group_id).group_id).to eq(group_id)
        end
      end
    end
  end
end
