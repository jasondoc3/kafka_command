module KafkaCommand
  class Broker
    attr_reader :cluster, :host

    def initialize(cluster:, host:, kafka_broker_id:)
      @cluster = cluster
      @host = host
      @kafka_broker_id = kafka_broker_id
    end

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
