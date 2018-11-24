require 'forwardable'
require_dependency 'kafka_command/cluster_wrapper'

module KafkaCommand
  class ClientWrapper
    extend Forwardable

    attr_reader :cluster, :client
    def_delegators :@client, :create_topic
    def_delegators :@cluster,
                   :brokers,
                   :topics,
                   :groups,
                   :refresh!,
                   :refresh_topics!,
                   :connect_to_broker

    def initialize(brokers:, **kwargs)
      @client = Kafka.new(brokers, **kwargs)
      @cluster = ClusterWrapper.new(@client.cluster)
    end

    def find_broker(host)
      hostname, port = host.split(':')

      @cluster.brokers.find do |b|
        hostname == b.host && port.to_i == b.port
      end
    end
  end
end
