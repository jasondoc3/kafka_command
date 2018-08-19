class Broker < ApplicationRecord
  HOST_REGEX = /[^\:]+:[0-9]{1,5}/
  belongs_to :cluster

  validates :host,
    presence: true,
    uniqueness: true,
    format: { with: HOST_REGEX, message: 'Must be a valid hostname port combination' }

  validates :kafka_broker_id, presence: { message: 'Cannot find Kafka broker ID' }

  def connected?
    client.topics
    true
  rescue Kafka::ConnectionError
    false
  end

  def client
    @client ||= cluster.client(seed_brokers: [host])
  end
end
