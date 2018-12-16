# frozen_string_literal: true

RSpec.describe KafkaCommand::Cluster do
  let(:cluster)    { described_class.all.first }
  let(:topic_name) { SecureRandom.hex(12) }

  describe '#new' do
    let(:brokers) { ENV['SEED_BROKERS'].split(',') }

    context 'plaintext' do
      it 'creates a kafka client with brokers and client id' do
        expect(KafkaCommand::Client).to receive(:new).with(
          hash_including(
            brokers: brokers,
            client_id: 'test_cluster'
          )
        ).at_least(:once)

        cluster

        expect(cluster.ssl?).to eq(false)
        expect(cluster.sasl?).to eq(false)
      end
    end

    context 'sasl config' do
      before do
        allow(KafkaCommand).to receive(:config).and_return(
          KafkaCommand::Configuration.new(KafkaCommand::Configuration.parse_yaml('spec/fixtures/files/kafka_command_sasl.yml'))
        )
      end

      it 'creates a kafka client with brokers, client_id, and sasl params' do
        expect(KafkaCommand::Client).to receive(:new).with(
          brokers: brokers,
          client_id: 'sasl_test_cluster',
          sasl_scram_username: 'test',
          sasl_scram_password: 'test',
          sasl_scram_mechanism: 'sha256',
          ssl_ca_cert: 'test_ca_cert'
        )

        cluster

        expect(cluster.sasl?).to eq(true)
      end
    end

    context 'ssl' do
      before do
        allow(KafkaCommand).to receive(:config).and_return(
          KafkaCommand::Configuration.new(KafkaCommand::Configuration.parse_yaml('spec/fixtures/files/kafka_command_ssl.yml'))
        )
      end

      it 'creates a kafka client with brokers, client_id, and ssl params' do
        expect(KafkaCommand::Client).to receive(:new).with(
          brokers: brokers,
          client_id: 'ssl_test_cluster',
          ssl_client_cert: 'test_client_cert',
          ssl_client_cert_key: 'test_client_cert_key',
          ssl_ca_cert: 'test_ca_cert'
        )

        cluster

        expect(cluster.ssl?).to eq(true)
        expect(cluster.sasl?).to eq(false)
      end
    end
  end

  describe '#create_topic' do
    let(:kwargs) do
      { replication_factor: 1, num_partitions: 1 }
    end

    it 'calls KafkaCommand::Client#create_topic' do
      expect_any_instance_of(KafkaCommand::Client).to receive(:create_topic).with(topic_name, **kwargs)
      cluster.create_topic(topic_name, **kwargs)
    end

    it 'creates a topic' do
      topic_count = cluster.topics.count
      topic = cluster.create_topic(topic_name, **kwargs)
      expect(topic).to be_an_instance_of(KafkaCommand::Topic)
      cluster.client.refresh_topics!
      expect(cluster.topics.count).to eq(topic_count + 1)
    end
  end

  describe '#to_s' do
    it 'returns the name' do
      expect(cluster.to_s).to eq(cluster.name)
    end
  end

  describe '.all' do
    it "returns a list of #{described_class}" do
      described_class.all.each do |c|
        expect(c).to be_an_instance_of(described_class)
      end
    end
  end

  describe '.find' do
    context 'cluster exists' do
      it 'finds the cluster' do
        expect(described_class.find(cluster.name)).to eq(cluster)
      end
    end

    context 'cluster does not exist' do
      it 'returns nil' do
        expect(described_class.find('doesnotexists')).to be_nil
      end
    end
  end

  context 'forwarding' do
    describe '#topics' do
      before { create_topic(topic_name) }

      it 'fowards the call to the KafkaCommand::Client' do
        expect(cluster.client).to receive(:topics).once
        cluster.topics
      end

      it 'returns a list of topics' do
        expect(cluster.topics.first).to be_an_instance_of(KafkaCommand::Topic)
        expect(cluster.topics.map(&:name)).to include(topic_name)
      end
    end

    describe '#brokers' do
      it 'fowards the call to the KafkaCommand::Client' do
        expect(cluster.client).to receive(:brokers).once
        cluster.brokers
      end

      it 'returns a list of brokers' do
        expect(cluster.brokers.first).to be_an_instance_of(KafkaCommand::Broker)
      end
    end

    describe '#groups' do
      before { create_topic(topic_name) }
      let(:group_id) { SecureRandom.hex(12) }

      it 'fowards to the call to the KafkaCommand::Client' do
        expect(cluster.client).to receive(:groups).once
        cluster.groups
      end

      it 'returns a list of groups' do
        run_consumer_group(topic_name, group_id) do
          expect(cluster.groups.first).to be_an_instance_of(KafkaCommand::ConsumerGroup)
          expect(cluster.groups.map(&:group_id)).to include(group_id)
        end
      end
    end
  end
end
