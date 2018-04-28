require 'fast_helper'
require 'securerandom'
require 'kafka'
require 'config/initializers/kafka'
require 'app/wrappers/kafka/client_wrapper'

RSpec.describe Kafka::ClientWrapper do
  let(:brokers)        { ['localhost:9092'] }
  let(:client_id)      { 'test_client' }
  let(:client_wrapper) { described_class.new(brokers: brokers, client_id: client_id) }

  describe '#new' do
    it 'creates a Kafka::ClientWrapper that wraps a Kafka::Client' do
      expect(client_wrapper.client).to be_an_instance_of(Kafka::Client)
      expect(client_wrapper.cluster).to be_an_instance_of(Kafka::ClusterWrapper)
    end
  end


  describe '#find_broker' do
    let(:client_wrapper) { described_class.new(brokers: brokers, client_id: client_id) }

    describe 'broker exists' do
      it 'returns a Kafka::BrokerWrapper' do
        broker = client_wrapper.find_broker(brokers.first)
        expect(broker).to be_an_instance_of(Kafka::BrokerWrapper)
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
          replication_factor: 1
        }
      end

      it 'forwards create_topic to the Kafka::Client' do
        expect(client_wrapper.client).to receive(:create_topic).with(topic_name, **topic_kwargs)
        client_wrapper.create_topic(topic_name, **topic_kwargs)
      end

      it 'creates a topic' do
        client_wrapper.create_topic(topic_name, topic_kwargs)
        expect(client_wrapper.client.topics).to include(topic_name)
      end
    end
  end
end
