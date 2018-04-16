class Cluster < ApplicationRecord

  has_many :brokers, dependent: :destroy
  validates :name, presence: true

  def client
    @client ||= Kafka::ClientWrapper.new(
      brokers: brokers.map(&:host),
      client_id: name
    )
  end

  def init_brokers(hosts)
    hosts.split(',').each do |h|
      brokers.new(host: h)
    end
  end

end
