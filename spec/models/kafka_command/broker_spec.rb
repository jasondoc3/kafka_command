require 'rails_helper'

RSpec.describe KafkaCommand::Broker do
  let(:cluster)   { build(:cluster_without_broker) }
  let(:hostname) { 'localhost' }
  let(:port)     { 9092 }
  subject { cluster.brokers.first }

  before do
    cluster.init_brokers("#{hostname}:#{port}")
    cluster.save!
  end

  it 'sets the kafka broker id when created' do
    expect(subject.reload.kafka_broker_id).to_not be_nil
  end

  describe '#hostname' do
    it 'returns the hostname' do
      expect(subject.hostname).to eq(hostname)
    end
  end

  describe '#port' do
    it 'returns the port' do
      expect(subject.port).to eq(port)
    end
  end

  describe '#kafka_broker' do
    it 'returns a Kafka::BrokerWrapper' do
      kafka_broker = subject.kafka_broker
      expect(kafka_broker).to be_an_instance_of(KafkaCommand::BrokerWrapper)
      expect(kafka_broker.port).to eq(port)
      expect(kafka_broker.host).to eq(hostname)
    end
  end

  describe '#connected?' do
    context 'when connected' do
      before do
        allow_any_instance_of(KafkaCommand::BrokerWrapper).to receive(:connected?).and_return(true)
      end

      it 'returns true' do
        expect(subject.connected?).to eq(true)
      end
    end

    context 'not connected' do
      before do
        allow_any_instance_of(KafkaCommand::BrokerWrapper).to receive(:connected?).and_return(false)
      end

      it 'returns false' do
        expect(subject.connected?).to eq(false)
      end
    end
  end
end
