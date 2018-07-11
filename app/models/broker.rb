class Broker < ApplicationRecord
  belongs_to :cluster
  after_initialize :set_broker_id

  validates :host,
    presence: true,
    uniqueness: true,
    format: { with: /[^\:]+:[0-9]{1,5}/, message: 'Must be a valid hostname port combination' }

  validates :kafka_broker_id, presence: true, uniqueness: true

  def set_broker_id
    if kafka_broker_id.blank? && valid_host?
      self.kafka_broker_id = client.find_broker(host).node_id
    end
  end

  def connected?
    client.topics
    true
  rescue Kafka::ConnectionError
    false
  end

  def client
    @client ||= Kafka::ClientWrapper.new(brokers: [host])
  end

  private

  def valid_host?
    valid?
    errors[:host].blank?
  end
end
