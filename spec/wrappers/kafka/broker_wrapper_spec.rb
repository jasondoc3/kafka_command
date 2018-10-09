require 'app/wrappers/kafka/client_wrapper'

RSpec.describe Kafka::BrokerWrapper do
  let(:broker) do
    Kafka::ClientWrapper
      .new(brokers: ['localhost:9092'])
      .cluster
      .brokers
      .sample
  end

  describe '#new' do
    it 'wraps a Kafka::Broker' do
      expect(broker.broker).to be_an_instance_of(Kafka::Broker)
    end
  end

  describe '#connected' do
    context 'when connected' do
      it 'returns true' do
        expect(broker.connected?).to eq(true)
      end
    end

    context 'when not connected' do
      before do
        allow(broker.broker).to receive(:api_versions).and_raise(Kafka::ConnectionError)
      end

      it 'returns false' do
        expect(broker.connected?).to eq(false)
      end
    end
  end

  context 'forwarding' do
    describe '#port' do
      it 'forwards port to the Kafka::Broker' do
        expect_any_instance_of(Kafka::Broker).to receive(:port)
        broker.port
      end

      it 'returns the port' do
        expect(broker.port).to eq(9092)
      end
    end

    describe '#host' do
      it 'forwards host to the Kafka::Broker' do
        expect(broker.broker).to receive(:host)
        broker.host
      end

      it 'returns the host' do
        expect(broker.host).to eq('localhost')
      end
    end

    describe '#node_id' do
      it 'forwards node_id to the Kafka::Broker' do
        expect(broker.broker).to receive(:node_id)
        broker.node_id
      end

      it 'returns the node_id' do
        expect(broker.node_id).to eq(broker.broker.node_id)
      end
    end

    describe '#fetch_metadata' do
      it 'forwards fetch_metdata to the Kafka::Broker' do
        expect(broker.broker).to receive(:fetch_metadata).and_call_original
        broker.fetch_metadata
      end

      it 'returns an instance of Kafka::Protocol::MetadataResponse' do
        expect(broker.fetch_metadata).to be_an_instance_of(Kafka::Protocol::MetadataResponse)
      end
    end
  end
end
