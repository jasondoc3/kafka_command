class Cluster < ApplicationRecord
  has_many :brokers, dependent: :destroy
  validates :name, presence: true

  attr_encrypted :sasl_scram_password, key: Base64.decode64(ENV.fetch('KAFKA_COMMAND_ENCRYPTION_KEY'))
  attr_encrypted :ssl_ca_cert, key: Base64.decode64(ENV.fetch('KAFKA_COMMAND_ENCRYPTION_KEY'))

  def self.client(**kwargs)
    @client ||= begin
      Kafka::ClientWrapper.new(**kwargs, logger: Rails.logger)
    end
  end

  def client(seed_brokers: nil)
    hosts = seed_brokers || brokers.map(&:host)

    client_kwargs = {
      brokers: hosts,
      client_id: name
    }

    if sasl?
      client_kwargs[:sasl_scram_username] = sasl_scram_username
      client_kwargs[:sasl_scram_password] = sasl_scram_password
      client_kwargs[:sasl_scram_mechanism] = 'sha256'
      client_kwargs[:sasl_over_ssl] = ssl_ca_cert.present?
      client_kwargs[:ssl_ca_cert] = ssl_ca_cert
    end

    self.class.client(**client_kwargs)
  end

  def topics
    client.refresh!
    client.topics
  end

  def connected?
    brokers.all?(&:connected?)
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

  private

    def sasl?
      sasl_scram_username.present? && sasl_scram_password.present?
    end
end
