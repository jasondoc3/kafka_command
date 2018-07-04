require 'rails_helper'

RSpec.describe 'Clusters Api', type: :request do
  let!(:cluster) { create(:cluster) }

  describe 'listing all clusters' do
    let!(:cluster_two) { create(:cluster) }

    it 'lists' do
      get '/clusters.json'
      expect(response.status).to eq(200)
      expect(json['data']).to be_an_instance_of(Array)
      expect(json['data'].map { |d| d['id'] }).to eq([cluster.id, cluster_two.id])
    end
  end

  describe 'showing a single cluster' do
    context 'cluster exists' do
      it 'shows' do
        get "/clusters/#{cluster.id}.json"
        expect(response.status).to eq(200)
        expect(json['id']).to eq(cluster.id)
        expect(json['name']).to eq(cluster.name)
        expect(json['version']).to eq(cluster.version)
        expect(json['description']).to eq(cluster.description)
      end
    end

    context 'cluster does not exist' do
      before { cluster.destroy }

      it 'returns 404' do
        get "/clusters/#{cluster.id}.json"
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'creating a cluster' do
    let(:hosts) { 'localhost:9092' }
    let(:cluster_params) do
      {
        name: 'test',
        description: 'description of test',
        version: '0.11.1',
        hosts: hosts
      }
    end

    it 'creates a new cluster' do
      expect do
        post '/clusters.json', params: cluster_params
        expect(response.status).to eq(201)
        expect(json['name']).to eq(cluster_params[:name])
        expect(json['description']).to eq(cluster_params[:description])
        expect(json['version']).to eq(cluster_params[:version])
      end.to change { Cluster.count }.by(1)
    end

    it 'creates brokers with the cluster' do
      expect do
        post '/clusters.json', params: cluster_params
        expect(response.status).to eq(201)
        cluster = Cluster.find(json['id'])
        expect(cluster.brokers.map(&:host)).to eq(cluster_params[:hosts].split(','))
      end.to change { Broker.count }.by(1)
    end

    context 'invalid hosts' do
      describe 'no hosts' do
        let(:hosts) { '' }

        it 'returns 422' do
          expect do
            post '/clusters.json', params: cluster_params
            expect(response.status).to eq(422)
            expect(response.body).to eq('Please specify the hosts')
          end.to change { Cluster.count }.by(0)
        end
      end

      describe 'invalid host name' do
        let(:hosts) { 'badhost' }

        it 'returns 422' do
          expect do
            post '/clusters.json', params: cluster_params
            expect(response.status).to eq(422)
          end.to change { Cluster.count }.by(0)
        end
      end

      describe 'cannot connect to host' do
        let(:hosts) { 'localhost:1' }

        it 'returns 500' do
          expect do
            post '/clusters.json', params: cluster_params
            expect(response.status).to eq(500)
            expect(response.body).to eq('Could not connect to Kafka with the specified brokers')
          end.to change { Cluster.count }.by(0)
        end
      end
    end
  end

  describe 'destroying a cluster' do
    context 'cluster exists' do
      it 'destroys' do
        expect do
          delete "/clusters/#{cluster.id}"
          expect(response.status).to eq(204)
        end.to change { Cluster.count }.by(-1)
      end

      it 'destroys the broker' do
        expect do
          delete "/clusters/#{cluster.id}"
          expect(response.status).to eq(204)
        end.to change { Broker.count }.by(-cluster.brokers.count)
      end
    end

    context 'cluster does not exist' do
      before { cluster.destroy }

      it 'returns not found' do
        expect do
          delete "/clusters/#{cluster.id}"
        end.to change { Cluster.count }.by(0)
      end
    end
  end
end
