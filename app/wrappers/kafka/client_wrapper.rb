require 'forwardable'

module Kafka
  class ClientWrapper
    extend Forwardable
    attr_reader :cluster
    def_delegators :@client, :create_topic

    def initialize(brokers:, client_id: nil)
      @client = Kafka.new(brokers, client_id: client_id)
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
