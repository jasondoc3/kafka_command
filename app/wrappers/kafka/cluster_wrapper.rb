require 'forwardable'
require_dependency 'app/wrappers/kafka/broker_wrapper'
require_dependency 'app/wrappers/kafka/consumer_group_wrapper'
require_dependency 'app/wrappers/kafka/topic_wrapper'

module Kafka
  class ClusterWrapper
    extend Forwardable
    attr_reader :cluster

    METHOD_DELGATIONS = %i(
      delete_topic
      alter_topic
      describe_topic
      create_partitions_for
      resolve_offset
      resolve_offsets
      describe_group
    ).freeze

    def_delegators :@cluster, *METHOD_DELGATIONS

    def initialize(cluster)
      @cluster = cluster
    end

    def refresh!
      refresh_brokers!
      refresh_topics!
      refresh_groups!
    end

    def topics
      @topics ||= initialize_topics
    end

    def brokers
      @brokers ||= initialize_brokers
    end

    def groups
      @groups ||= initialize_groups
    end

    def refresh_groups!
      @groups = initialize_groups
    end

    def refresh_topics!
      @topics = initialize_topics
    end

    def refresh_brokers!
     @brokers = initialize_brokers
    end

    def fetch_metadata(topics: nil)
      brokers.sample.fetch_metadata(topics: topics)
    end

    def get_group_coordinator(group_id:)
      broker = @cluster.get_group_coordinator(group_id: group_id)
      BrokerWrapper.new(broker)
    end

    def find_topic(topic_name)
      topics.find { |t| t.name == topic_name }
    end

    private

    def initialize_brokers
      # returns information about each broker in the cluster
      # i.e node_id, port, host
      cluster_info = @cluster.refresh_metadata!

      cluster_info.brokers.each do |broker|
        @cluster.broker_pool.connect(broker.host, broker.port, node_id: broker.node_id)
      end

      @cluster.broker_pool.brokers.map do |_, broker|
        BrokerWrapper.new(broker)
      end
    end

    def initialize_topics
      # returns information about each topic
      # i.e isr, leader, partitions
      fetch_metadata.topics.map { |tm| TopicWrapper.new(tm, self) }
    end

    def initialize_groups
      group_ids = @cluster.list_groups

      group_ids.map do |g|
        group_metadata = @cluster.describe_group(g)
        ConsumerGroupWrapper.new(group_metadata, self)
      end
    end
  end
end
