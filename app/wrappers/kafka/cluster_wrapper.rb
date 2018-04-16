module Kafka
  class ClusterWrapper
    attr_reader :brokers, :cluster

    def initialize(cluster)
      @cluster = cluster
      initialize_brokers
    end

    private

    def initialize_brokers
      cluster_info = @cluster.refresh_metadata!

      cluster_info.brokers.each do |broker|
        @cluster.broker_pool.connect(broker.host, broker.port, node_id: broker.node_id)
      end

      @brokers = @cluster.broker_pool.brokers.map do |broker_id, broker|
        BrokerWrapper.new(broker)
      end
    end
  end
end
