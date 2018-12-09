require 'rails_helper'

RSpec.describe 'Clusters Api', type: :request do
  let!(:cluster) { KafkaCommand::Cluster.all.first }

  describe 'listing all clusters' do
    let!(:cluster_two) { KafkaCommand::Cluster.new(seed_brokers: ['localhost:9092'], name: 'cluster_two') }

    before do
      allow(KafkaCommand::Cluster).to receive(:all).and_return([cluster, cluster_two])
    end

    it 'lists' do
      get '/clusters.json'
      expect(response.status).to eq(200)
      expect(json['data']).to be_an_instance_of(Array)
      expect(json['data'].map { |d| d['name'] }).to eq([cluster.name, cluster_two.name])
    end

    context 'filtering' do
      it 'filters by name' do
        get "/clusters.json?name=#{cluster.name}"
        expect(response.status).to eq(200)
        expect(json['data']).to be_an_instance_of(Array)
        expect(json['data'].map { |d| d['name'] }).to include(cluster.name)
        expect(json['data'].map { |d| d['name'] }).to_not include(cluster_two.name)
      end

      it 'filters by name' do
        get "/clusters.json?name=unknown"
        expect(response.status).to eq(200)
        expect(json['data']).to be_an_instance_of(Array)
        expect(json['data']).to be_empty
      end
    end
  end

  describe 'showing a single cluster' do
    context 'cluster exists' do
      it 'shows' do
        get "/clusters/#{cluster.name}.json"
        expect(response.status).to eq(200)
        expect(json['name']).to eq(cluster.name)
        expect(json['version']).to eq(cluster.version)
        expect(json['description']).to eq(cluster.description)
      end
    end

    context 'cluster does not exist' do
      it 'returns 404' do
        get "/clusters/doesnotexist.json"
        expect(response.status).to eq(404)
      end
    end
  end
end
