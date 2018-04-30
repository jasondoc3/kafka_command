require 'forwardable'
require_dependency 'app/wrappers/kafka/broker_wrapper'
require_dependency 'app/wrappers/kafka/topic_wrapper'

module Kafka
  class ClusterWrapper
    extend Forwardable
    attr_reader :brokers, :cluster, :topics
    def_delegators :@cluster, :delete_topic, :create_partitions_for

    def initialize(cluster)
      @cluster = cluster
      refresh!
    end

    def refresh!
      initialize_brokers
      initialize_topics
    end

    def fetch_metadata(topics: nil)
      @brokers.sample.fetch_metadata(topics: topics)
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
      @topics = fetch_metadata.topics.map { |tm| TopicWrapper.new(tm, self) }
    end
  end
end
