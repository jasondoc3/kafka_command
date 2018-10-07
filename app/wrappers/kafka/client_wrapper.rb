require 'forwardable'
require_dependency 'app/wrappers/kafka/cluster_wrapper'

module Kafka
  class ClientWrapper
    extend Forwardable

    attr_reader :cluster, :client
    def_delegators :@client, :create_topic
    def_delegators :@cluster, :topics, :groups, :refresh!, :refresh_topics!

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
