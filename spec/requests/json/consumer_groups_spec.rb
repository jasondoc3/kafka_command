# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Consumer Groups Api', type: :request do
  let(:cluster) { KafkaCommand::Cluster.all.first }
  let(:topic_name) { "test-#{SecureRandom.hex(12)}" }
  let(:group_id_1) { "test-group-#{SecureRandom.hex(12)}" }
  let(:group_id_2) { "test-group-#{SecureRandom.hex(12)}" }
  let(:uri_base) { "/clusters/#{cluster.id}/" }
  let(:expected_json_group_1_running) do
    {
      group_id: group_id_1,
      state: 'Stable',
      topics: [
        {
          name: topic_name,
          partitions: [
            {
              partition_id: 0,
              lag: nil,
              offset: nil
            }
          ]
        }
      ]
    }.with_indifferent_access
  end

  let(:expected_json_group_1_empty) do
    {
      group_id: group_id_1,
      topics: [],
      state: 'Empty'
    }.with_indifferent_access
  end

  let(:expected_json_group_2_empty) do
    {
      group_id: group_id_2,
      topics: [],
      state: 'Empty'
    }.with_indifferent_access
  end

  before { create_topic(topic_name) }

  describe 'listing all consumer groups' do
    describe 'dormant' do
      before do
        run_consumer_group(topic_name, group_id_1)
        run_consumer_group(topic_name, group_id_2)
      end

      it 'returns empty groups' do
        get "#{uri_base}/consumer_groups.json"
        expect(response.status).to eq(200)
        expect(json['data']).to be_an_instance_of(Array)
        expect(json['data']).to include(expected_json_group_1_empty)
        expect(json['data']).to include(expected_json_group_2_empty)
      end

      context 'filtering' do
        it 'filters by group id' do
          get "#{uri_base}/consumer_groups.json?group_id=#{group_id_1}"
          expect(response.status).to eq(200)
          expect(json['data']).to be_an_instance_of(Array)
          expect(json['data']).to include(expected_json_group_1_empty)
          expect(json['data']).to_not include(expected_json_group_2_empty)
        end

        it 'filters by group id' do
          get "#{uri_base}/consumer_groups.json?group_id=unknown"
          expect(response.status).to eq(200)
          expect(json['data']).to be_an_instance_of(Array)
          expect(json['data']).to be_empty
        end
      end
    end

    describe 'running ' do
      let(:expected_json) do
        {
          group_id: group_id_1,
          state: 'Stable',
          topics: [
            {
              name: topic_name,
              partitions: [
                {
                  partition_id: 0,
                  lag: nil,
                  offset: nil
                }
              ]
            }
          ]
        }.with_indifferent_access
      end

      it 'returns non empty groups' do
        run_consumer_group(topic_name, group_id_1) do
          get "#{uri_base}/consumer_groups.json"
          expect(json['data']).to include(expected_json)
        end
      end
    end
  end

  describe 'showing a consumer group' do
    context 'dormant' do
      before { run_consumer_group(topic_name, group_id_1) }

      it 'returns an empty group' do
        get "#{uri_base}/consumer_groups/#{group_id_1}.json"
        expect(response.status).to eq(200)
        expect(json).to eq(expected_json_group_1_empty)
      end
    end

    context 'running' do
      it 'returns an empty group' do
        run_consumer_group(topic_name, group_id_1) do
          get "#{uri_base}/consumer_groups/#{group_id_1}.json"
          expect(response.status).to eq(200)
          expect(json).to eq(expected_json_group_1_running)
        end
      end
    end

    context 'not found' do
      it 'returns 404' do
        get "#{uri_base}/consumer_groups/doesnotexists.json"
        expect(response.status).to eq(404)
        expect(response.body).to eq('Consumer group not found')
      end
    end
  end
end
