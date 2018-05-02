require 'forwardable'

module Kafka
  class BrokerWrapper
    extend Forwardable
    attr_reader :broker
    def_delegators :@broker, :port, :host, :node_id, :fetch_metadata

    def initialize(broker)
      @broker = broker
    end
  end
end
