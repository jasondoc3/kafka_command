require 'rails_helper'

RSpec.describe 'Clusters Api', type: :request do
  let!(:cluster_one) { create(:cluster) }
  let!(:cluster_two) { create(:cluster) }

  describe 'listing all clusters' do
    it 'lists' do
      get '/api/v1/clusters'
      expect(response.status).to eq(200)
      expect(json['data']).to be_an_instance_of(Array)
      expect(json['data'].map { |d| d['id'] }).to eq([cluster_one.id, cluster_two.id])
    end
  end

  describe 'showing a single cluster' do
    context 'cluster exists' do
      it 'shows' do
        get "/api/v1/clusters/#{cluster_one.id}"
        expect(response.status).to eq(200)
        expect(json['id']).to eq(cluster_one.id)
        expect(json['name']).to eq(cluster_one.name)
        expect(json['version']).to eq(cluster_one.version)
        expect(json['description']).to eq(cluster_one.description)
      end
    end

    context 'cluster does not exist' do
      before { cluster_one.destroy }

      it 'returns not found' do
        get "/api/v1/clusters/#{cluster_one.id}"
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'destroying a cluster' do
    context 'cluster exists' do
      it 'destroys' do
        expect do
          delete "/api/v1/clusters/#{cluster_one.id}"
          expect(response.status).to eq(204)
        end.to change { Cluster.count }.by -1
      end
    end

    context 'cluster does not exist' do
      before { cluster_one.destroy }

      it 'returns not found' do
        expect do
          delete "/api/v1/clusters/#{cluster_one.id}"
        end.to change { Cluster.count }.by 0
      end
    end
  end
end
