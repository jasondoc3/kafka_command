class Broker < ApplicationRecord
  belongs_to :cluster
  after_create :set_broker_id

  validates :host, presence: true, uniqueness: true

  def set_broker_id
    self.kafka_broker_id = cluster.client.find_broker(host).node_id
  end
end
