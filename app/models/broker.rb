require 'forwardable'

class Broker < ApplicationRecord
  extend Forwardable
  def_delegator :cluster, :client
  belongs_to :cluster
  before_save :set_broker_id

  validates :host, presence: true, uniqueness: true

  def set_broker_id
    self.kafka_broker_id = client.find_broker(host).node_id
  end
end
