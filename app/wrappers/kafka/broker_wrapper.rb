require 'forwardable'

module Kafka
  class BrokerWrapper
    extend Forwardable
    def_delegators :@broker, :port, :host, :node_id, :fetch_metadata

    def initialize(broker)
      @broker = broker
    end
  end
end
