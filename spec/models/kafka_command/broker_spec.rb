# frozen_string_literal: true

require 'app/models/kafka_command/broker'

RSpec.describe KafkaCommand::Broker do
  let(:hostname) { 'localhost' }
  let(:port)     { 9092 }
  subject        { KafkaCommand::Cluster.all.first.brokers.first }

  describe '#new' do
    it 'wraps a Kafka::Broker' do
      expect(subject.broker).to be_an_instance_of(Kafka::Broker)
    end
  end

  describe '#connected' do
    context 'when connected' do
      it 'returns true' do
        expect(subject.connected?).to eq(true)
      end
    end

    context 'when not connected' do
      before do
        allow(subject.broker).to receive(:api_versions).and_raise(Kafka::ConnectionError)
      end

      it 'returns false' do
        expect(subject.connected?).to eq(false)
      end
    end
  end

  context 'forwarding' do
    describe '#port' do
      it 'forwards port to the Kafka::Broker' do
        expect_any_instance_of(Kafka::Broker).to receive(:port)
        subject.port
      end

      it 'returns the port' do
        expect(subject.port).to eq(9092)
      end
    end

    describe '#host' do
      it 'forwards host to the Kafka::Broker' do
        expect(subject.broker).to receive(:host)
        subject.host
      end

      it 'returns the host' do
        expect(subject.host).to eq('localhost')
      end
    end

    describe '#node_id' do
      it 'forwards node_id to the Kafka::Broker' do
        expect(subject.broker).to receive(:node_id)
        subject.node_id
      end

      it 'returns the node_id' do
        expect(subject.node_id).to eq(subject.broker.node_id)
      end
    end

    describe '#fetch_metadata' do
      it 'forwards fetch_metdata to the Kafka::Broker' do
        expect(subject.broker).to receive(:fetch_metadata).and_call_original
        subject.fetch_metadata
      end

      it 'returns an instance of Kafka::Protocol::MetadataResponse' do
        expect(subject.fetch_metadata).to be_an_instance_of(Kafka::Protocol::MetadataResponse)
      end
    end
  end

  describe '#host_with_port' do
    it 'returns the host and port combination' do
      expect(subject.hostname).to eq(hostname)
    end
  end
end
