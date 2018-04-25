class Cluster < ApplicationRecord
  has_many :brokers, dependent: :destroy
  validates :name, presence: true

  def client
    @client ||= Kafka::ClientWrapper.new(
      brokers: brokers.map(&:host),
      client_id: name
    )
  end

  def topics
    client.cluster.topics
  end

  def create_topic(name, **kwargs)
    client.cluster.create_topic(name, **kwargs)
    client.cluster.refresh!
  end

  def init_brokers(hosts)
    hosts.split(',').each do |h|
      brokers.new(host: h)
    end
  end

end
