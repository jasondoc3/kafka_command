require 'forwardable'

module Kafka
  class BrokerWrapper
    extend Forwardable
    def_delegators :@broker, :port, :host, :node_id

    def initialize(broker)
      @broker = broker
    end
  end
end
