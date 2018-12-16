# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Brokers Api', type: :request do
  let(:cluster) { KafkaCommand::Cluster.all.first }
  let(:broker) { cluster.brokers.first }
  let(:uri_base) { '/clusters' }

  describe 'listing all brokers' do
    let(:broker_obj) { double(:broker_obj, node_id: 0, host: 'localhost', port: '9092') }
    let(:broker_obj_two) { double(:broker_obj, node_id: 1, host: 'localhost2', port: '9092') }
    let(:broker) { KafkaCommand::Broker.new(broker_obj) }
    let(:broker_two) { KafkaCommand::Broker.new(broker_obj_two) }

    before do
      allow_any_instance_of(KafkaCommand::Cluster).to receive(:brokers).and_return(
        [
          broker,
          broker_two
        ]
      )
    end

    it 'lists' do
      get "#{uri_base}/#{cluster.name}/brokers.json"
      expect(response.status).to eq(200)
      expect(json['data']).to be_an_instance_of(Array)
      expect(json['data'].map { |d| d['id'] }).to eq([broker.node_id, broker_two.node_id])
    end
  end

  describe 'showing a single broker' do
    context 'broker exists' do
      it 'shows' do
        get "#{uri_base}/#{cluster.name}/brokers/#{broker.node_id}.json"
        expect(response.status).to eq(200)
        expect(json['id']).to eq(broker.node_id)
        expect(json['host']).to eq("#{broker.host}:#{broker.port}")
      end
    end

    context 'broker does not exist' do
      it 'returns 404' do
        get "#{uri_base}/#{cluster.name}/brokers/doesnotexist.json"
        expect(response.status).to eq(404)
      end
    end
  end
end
