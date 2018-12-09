require 'forwardable'
require_dependency 'app/models/kafka_command/broker'
require_dependency 'app/models/kafka_command/consumer_group'
require_dependency 'app/models/kafka_command/topic'

module KafkaCommand
  class Client
    extend Forwardable

    CLUSTER_METHOD_DELGATIONS = %i(
      broker_pool
      delete_topic
      alter_topic
      describe_topic
      create_partitions_for
      resolve_offset
      resolve_offsets
      describe_group
    ).freeze

    attr_reader :cluster, :client
    def_delegators :@client, :create_topic
    def_delegators :@cluster, *CLUSTER_METHOD_DELGATIONS

    def initialize(brokers:, **kwargs)
      @client = Kafka.new(brokers, **kwargs)
      @cluster = @client.cluster
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
      Broker.new(broker)
    end

    def find_topic(topic_name)
      topics.find { |t| t.name == topic_name }
    end

    def connect_to_broker(host:, port:, broker_id:)
      Broker.new(broker_pool.connect(host, port, node_id: broker_id))
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
      fetch_metadata.topics.map { |tm| Topic.new(tm, self) }
    end

    def initialize_groups
      group_ids = @cluster.list_groups
      group_ids.map { |id| ConsumerGroup.new(id, self) }
    end
  end
end
