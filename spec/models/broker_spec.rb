require 'rails_helper'

RSpec.describe Broker do
  let(:broker)       { build(:broker) }
  let(:cluster)      { create(:cluster, brokers: [broker]) }

  it 'sets the kafka broker id when created' do
    cluster # creates a cluster with a broker
    expect(broker.reload.kafka_broker_id).to_not be_nil
  end
end
