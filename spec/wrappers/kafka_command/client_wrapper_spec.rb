require 'app/wrappers/kafka_command/client_wrapper'

RSpec.describe KafkaCommand::ClientWrapper do
  let(:brokers)        { ['localhost:9092'] }
  let(:client_id)      { 'test_client' }
  let(:client_wrapper) { described_class.new(brokers: brokers, client_id: client_id) }

  describe '#new' do
    it 'creates a Kafka::ClientWrapper that wraps a Kafka::Client' do
      expect(client_wrapper.client).to be_an_instance_of(Kafka::Client)
      expect(client_wrapper.cluster).to be_an_instance_of(KafkaCommand::ClusterWrapper)
    end
  end

  describe '#find_broker' do
    let(:client_wrapper) { described_class.new(brokers: brokers, client_id: client_id) }

    describe 'broker exists' do
      it 'returns a KafkaCommand::BrokerWrapper' do
        broker = client_wrapper.find_broker(brokers.first)
        expect(broker).to be_an_instance_of(KafkaCommand::BrokerWrapper)
      end
    end

    describe 'broker does not exist' do
      it 'returns nil' do
        broker = client_wrapper.find_broker('helloworld:9092')
        expect(broker).to be_nil
      end
    end
  end

  context 'forwarding' do
    describe '#create_topic' do
      let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
      let(:topic_kwargs) do
        {
          num_partitions: 10,
          replication_factor: 1,
          config: {
            'retention.ms' => 1024,
            'retention.bytes' => 6000,
            'max.message.bytes' => 1204
          }
        }
      end

      it 'forwards create_topic to the Kafka::Client' do
        expect(client_wrapper.client).to receive(:create_topic).with(topic_name, **topic_kwargs)
        client_wrapper.create_topic(topic_name, **topic_kwargs)
      end

      context 'topic creation' do
        after { delete_topic(topic_name) }

        it 'creates a topic' do
          expect(topic_exists?(topic_name)).to eq(false)
          client_wrapper.create_topic(topic_name, topic_kwargs)
          expect(topic_exists?(topic_name)).to eq(true)
        end
      end
    end

    describe '#topics' do
      it' forwards #topics to the KafkaCommand::ClusterWrapper' do
        expect(client_wrapper.cluster).to receive(:topics)
        client_wrapper.topics
      end
    end

    describe '#groups' do
      it 'forwards #groups to the KafkaCommand::ClusterWrapper' do
        expect(client_wrapper.cluster).to receive(:groups)
        client_wrapper.groups
      end
    end

    describe '#refresh!' do
      it 'forwards #refresh! to the KafkaCommand::ClusterWrapper' do
        expect(client_wrapper.cluster).to receive(:refresh!)
        client_wrapper.refresh!
      end
    end

    describe '#refresh_topics!' do
      it 'forwards #refresh_topics! to the KafkaCommand::ClusterWrapper' do
        expect(client_wrapper.cluster).to receive(:refresh_topics!)
        client_wrapper.refresh_topics!
      end
    end

    describe '#connect_to_broker' do
      it 'forwards #connect_to_broker to the KafkaCommand::ClusterWrapper' do
        expect(client_wrapper.cluster).to receive(:connect_to_broker)
        client_wrapper.connect_to_broker(host: 'localhost', port: 9092, broker_id: 1)
      end
    end
  end
end
