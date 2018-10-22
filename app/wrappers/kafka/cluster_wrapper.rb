require 'forwardable'
require_dependency 'app/wrappers/kafka/broker_wrapper'
require_dependency 'app/wrappers/kafka/consumer_group_wrapper'
require_dependency 'app/wrappers/kafka/topic_wrapper'

module Kafka
  class ClusterWrapper
    extend Forwardable
    attr_reader :cluster

    METHOD_DELGATIONS = %i(
      broker_pool
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

    def connect_to_broker(host:, port:, broker_id:)
      BrokerWrapper.new(broker_pool.connect(host, port, node_id: broker_id))
    end

    private

    def initialize_brokers
      cluster_info = @cluster.refresh_metadata!

      cluster_info.brokers.map do |broker|
        connect_to_broker(
          host: broker.host,
          port: broker.port,
          broker_id: broker.node_id
        )
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
