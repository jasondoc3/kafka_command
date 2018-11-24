require_dependency 'kafka_command/application_record'

module KafkaCommand
  class Cluster < ApplicationRecord
    has_many :brokers, dependent: :destroy
    validates :name, presence: true
    validates :brokers, presence: true
    validates_associated :brokers

    ENCRYPTION_KEY = Base64.decode64(ENV.fetch('KAFKA_COMMAND_ENCRYPTION_KEY'))

    %i(
      sasl_scram_password
      ssl_ca_cert
      ssl_client_cert
      ssl_client_cert_key
    ).each { |attribute| attr_encrypted attribute, key: ENCRYPTION_KEY }

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
        client_kwargs[:ssl_ca_cert] = ssl_ca_cert
      elsif ssl?
        client_kwargs[:ssl_ca_cert] = ssl_ca_cert
        client_kwargs[:ssl_client_cert] = ssl_client_cert
        client_kwargs[:ssl_client_cert_key] = ssl_client_cert_key
        client_kwargs
      end

      ClientWrapper.new(**client_kwargs, logger: Rails.logger)
    end

    def topics
      client.topics
    end

    def connected?
      # Tried using all?(&:connected?) here, but was getting some weird behavior with the views
      brokers.map(&:connected?).all?
    end

    def groups
      client.groups
    end

    def create_topic(name, **kwargs)
      client.create_topic(name, **kwargs)
      client.refresh_topics!
      topics.find { |t| t.name == name }
    end

    def init_brokers(hosts)
      client(seed_brokers: hosts.split(',')).cluster.brokers.each do |broker|
        brokers.new(host: "#{broker.host}:#{broker.port}", kafka_broker_id: broker.node_id)
      end
    end

    def to_human
      name.humanize.capitalize
    end

    def ssl?
      encrypted_ssl_ca_cert.present? &&
        encrypted_ssl_client_cert.present? &&
        encrypted_ssl_client_cert_key.present?
    end

    def sasl?
      sasl_scram_username.present? && sasl_scram_password.present?
    end
  end
end
