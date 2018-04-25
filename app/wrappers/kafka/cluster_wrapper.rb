require 'forwardable'

module Kafka
  class ClusterWrapper
    extend Forwardable
    attr_reader :brokers, :topics
    def_delegators :@cluster, :create_topic, :describe_topic, :alter_topic

    def initialize(cluster)
      @cluster = cluster
      refresh!
    end

    def refresh!
      initialize_brokers
      initialize_topics
    end

    private

    def initialize_brokers
      # returns information about each broker in the cluster
      # i.e node_id, port, host
      cluster_info = @cluster.refresh_metadata!

      cluster_info.brokers.each do |broker|
        @cluster.broker_pool.connect(broker.host, broker.port, node_id: broker.node_id)
      end

      @brokers = @cluster.broker_pool.brokers.map do |broker_id, broker|
        BrokerWrapper.new(broker)
      end
    end

    def initialize_topics
      # returns information about each topic
      # i.e isr, leader, partitions
      topic_metadata = @brokers.sample.fetch_metadata(topics: nil)
      @topics = topic_metadata.topics.map { |tm| TopicWrapper.new(tm, @cluster) }
    end
  end
end
