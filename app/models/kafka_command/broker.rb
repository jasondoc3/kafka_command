require_dependency 'kafka_command/application_record'

module KafkaCommand
  class Broker < ApplicationRecord
    HOST_REGEX = /[^\:]+:[0-9]{1,5}/
    belongs_to :cluster

    validates :host,
      presence: true,
      uniqueness: true,
      format: { with: HOST_REGEX, message: 'Must be a valid hostname port combination' }

    validates :kafka_broker_id, presence: { message: 'Cannot find Kafka broker ID' }

    def connected?
      kafka_broker.connected?
    end

    def client
      @client ||= cluster.client(seed_brokers: [host])
    end

    def hostname
      host.split(':').first
    end

    def port
      host.split(':').last.to_i
    end

    def kafka_broker
      client.connect_to_broker(
        host: hostname,
        port: port,
        broker_id: kafka_broker_id
      )
    end
  end
end