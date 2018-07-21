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
    client.refresh!
    client.topics
  end

  def groups
    client.refresh!
    client.groups
  end

  def create_topic(name, **kwargs)
    client.create_topic(name, **kwargs)
    client.refresh!
    topics.find { |t| t.name == name }
  end

  def init_brokers(hosts)
    hosts&.split(',').each do |h|
      brokers.new(host: h)
    end
  end

  def to_human
    name.humanize.capitalize
  end
end
