require 'rails_helper'

RSpec.describe 'Brokers Api', type: :request do
  let!(:cluster) { create(:cluster) }
  let!(:broker) { create(:broker, cluster: cluster) }
  let(:uri_base) { '/clusters' }

  before do
    allow_any_instance_of(Broker).to receive(:set_broker_id)
  end

  describe 'listing all brokers' do
    let!(:broker_two) { create(:broker, host: 'localhost:9093', cluster: cluster) }

    it 'lists' do
      get "#{uri_base}/#{broker.cluster.id}/brokers"
      expect(response.status).to eq(200)
      expect(json['data']).to be_an_instance_of(Array)
      expect(json['data'].map { |d| d['id'] }).to eq([broker.id, broker_two.id])
    end
  end

  describe 'showing a single broker' do
    context 'broker exists' do
      it 'shows' do
        get "#{uri_base}/#{broker.cluster.id}/brokers/#{broker.id}"
        expect(response.status).to eq(200)
        expect(json['id']).to eq(broker.id)
        expect(json['host']).to eq(broker.host)
        expect(json['kafka_broker_id']).to eq(broker.kafka_broker_id)
      end
    end

    context 'broker does not exist' do
      before { broker.destroy }

      it 'returns 404' do
        get "#{uri_base}/#{broker.cluster.id}/brokers/#{broker.id}"
        expect(response.status).to eq(404)
      end
    end
  end
end
