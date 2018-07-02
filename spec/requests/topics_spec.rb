require 'rails_helper'

RSpec.describe 'Topics API', type: :request do
  let(:cluster) { create(:cluster) }
  let!(:broker) { create(:broker, cluster: cluster) }
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  let(:num_partitions) { 5 }
  let(:replication_factor) { 1 }
  let(:uri_base) { '/clusters' }
  let(:create_topic_kwargs) do
    {
      num_partitions: num_partitions,
      replication_factor: replication_factor
    }
  end

  before { create_topic(topic_name, **create_topic_kwargs) }
  after { delete_topic(topic_name) if topic_exists?(topic_name) }

  describe 'listing all topics' do
    let(:topic_two_name) { "test-#{SecureRandom.hex(12)}" }

    before { create_topic(topic_two_name) }
    after  { delete_topic(topic_two_name) }

    it 'lists' do
      get "#{uri_base}/#{cluster.id}/topics.json"
      expect(response.status).to eq(200)
      expect(json['data']).to be_an_instance_of(Array)
      expect(json['data'].map { |d| d['name'] }).to include(topic_name)
      expect(json['data'].map { |d| d['name'] }).to include(topic_two_name)
    end
  end

  describe 'showing a topic' do
    context 'topic exists' do
      it 'shows' do
        get "#{uri_base}/#{cluster.id}/topics/#{topic_name}.json"
        expect(response.status).to eq(200)
        expect(json['name']).to eq(topic_name)
        expect(json['partitions']).to be_an_instance_of(Array)
        expect(json['partitions'].count).to eq(num_partitions)
        expect(json['replication_factor']).to eq(replication_factor)
      end
    end

    context 'topic does not exist' do
      it 'returns 404' do
        get "#{uri_base}/#{cluster.id}/topics/doesnotexist.json"
        expect(response.status).to eq(404)
        expect(response.body).to eq('Topic not found')
      end
    end
  end

  describe 'creating a topic' do
    let(:topic_two_name) { "test-#{SecureRandom.hex(12)}" }
    let(:new_num_partitions) { num_partitions }
    let(:new_replication_factor) { replication_factor }
    let(:create_topic_params) do
      {
        name: topic_two_name,
        replication_factor: new_replication_factor,
        num_partitions: new_num_partitions
      }
    end

    after { delete_topic(topic_two_name) if topic_exists?(topic_two_name) }

    it 'creates' do
      expect do
        post "#{uri_base}/#{cluster.id}/topics.json", params: create_topic_params
        expect(response.status).to eq(201)
        expect(json['name']).to eq(topic_two_name)
        expect(json['partitions']).to be_an_instance_of(Array)
        expect(json['partitions'].count).to eq(num_partitions)
        expect(json['replication_factor']).to eq(replication_factor)
      end.to change { cluster.topics.count }.by(1)
    end

    context 'invalid parameters' do
      describe 'no name' do
        let(:topic_two_name) { '' }

        it 'returns 422' do
          expect do
            post "#{uri_base}/#{cluster.id}/topics.json", params: create_topic_params
            expect(response.status).to eq(422)
            expect(response.body).to eq('Topic must have a name')
          end.to change { cluster.topics.count }.by(0)
        end
      end

      describe 'invalid partitions' do
        let(:new_num_partitions) { -1 }

        it 'returns 422' do
          expect do
            post "#{uri_base}/#{cluster.id}/topics.json", params: create_topic_params
            expect(response.status).to eq(422)
            expect(response.body).to eq('Num partitions must be > 0 or > current number of partitions')
          end.to change { cluster.topics.count }.by(0)
        end
      end

      describe 'invalid replication factor' do
        let(:error_message) do
          'Replication factor must be > 0 and < total number of brokers'
        end

        describe 'when 0' do
          let(:new_replication_factor) { 0 }

          it 'returns 422' do
            expect do
              post "#{uri_base}/#{cluster.id}/topics.json", params: create_topic_params
              expect(response.status).to eq(422)
              expect(response.body).to eq(error_message)
            end.to change { cluster.topics.count }.by(0)
          end
        end

        describe 'when > number of brokers' do
          let(:new_replication_factor) { cluster.brokers.count + 1 }

          it 'returns 422' do
            expect do
              post "#{uri_base}/#{cluster.id}/topics.json", params: create_topic_params
              expect(response.status).to eq(422)
              expect(response.body).to eq(error_message)
            end.to change { cluster.topics.count }.by(0)
          end
        end
      end
    end
  end

  describe 'updating a topic' do
    let(:topic) { cluster.topics.find { |t| t.name == topic_name } }
    let(:new_num_partitions) { num_partitions + 1 }
    let(:update_topic_params) do
      {
        num_partitions: new_num_partitions
      }
    end

    context 'topic exists' do
      it 'updates the topic' do
        patch "#{uri_base}/#{cluster.id}/topics/#{topic_name}.json", params: update_topic_params
        expect(response.status).to eq(200)
        expect(topic.partitions.count).to eq(update_topic_params[:num_partitions])
      end

      context 'invalid parameters' do
        describe 'invalid num partitions' do
          let(:new_num_partitions) { num_partitions - 1 }

          it 'returns 422' do
            patch "#{uri_base}/#{cluster.id}/topics/#{topic_name}.json", params: update_topic_params
            expect(response.status).to eq(422)
            expect(response.body).to eq('Num partitions must be > 0 or > current number of partitions')
          end
        end
      end
    end

    context 'topic does not exist' do
      it 'returns 404' do
        patch "#{uri_base}/#{cluster.id}/topics/nonexistent.json", params: update_topic_params
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'destroying a topic' do
    context 'topic exists' do
      it 'destroys' do
        expect do
          delete "#{uri_base}/#{cluster.id}/topics/#{topic_name}.json"
          expect(response.status).to eq(204)
        end.to change { cluster.topics.count }.by(-1)
      end
    end

    context 'topic does not exist' do
      before { delete_topic(topic_name) }

      it 'returns 404' do
        expect do
          delete "#{uri_base}/#{cluster.id}/topics/doesnotexist.json"
          expect(response.status).to eq(404)
          expect(response.body).to eq('Topic not found')
        end.to change { cluster.topics.count }.by(0)
      end
    end
  end
end
