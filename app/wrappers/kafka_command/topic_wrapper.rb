require_dependency 'kafka_command/partition_wrapper'

module KafkaCommand
  class TopicWrapper
    attr_reader :name,
                :partitions,
                :replication_factor,
                :max_message_bytes,
                :retention_ms,
                :retention_bytes

    alias_method :id, :name

    CLUSTER_API_TIMEOUT = 10
    CONSUMER_OFFSET_TOPIC = '__consumer_offsets'.freeze
    DEFAULT_MAX_MESSAGE_BYTES = 1000012
    DEFAULT_RETENTION_MS = 604800000
    DEFAULT_RETENTION_BYTES = -1
    TOPIC_CONFIGS = %w[
      max.message.bytes
      retention.bytes
      retention.ms
    ].freeze

    def initialize(topic_metadata, cluster)
      @cluster        = cluster
      @topic_metadata = topic_metadata
      initialize_from_metadata
    end

    def brokers_spread
      ((replication_factor.to_f / @cluster.brokers.count.to_f) * 100).round
    end

    def destroy
      @cluster.delete_topic(@name, timeout: CLUSTER_API_TIMEOUT)
    end

    def set_configs!(max_message_bytes: nil, retention_ms: nil, retention_bytes: nil)
      config = {}
      config['max.message.bytes'] = max_message_bytes if max_message_bytes
      config['retention.ms']      = retention_ms      if retention_ms
      config['retention.bytes']   = retention_bytes   if retention_bytes

      @cluster.alter_topic(@name, config) unless config.empty?
      refresh!
    end

    def set_partitions!(num_partitions)
      @cluster.create_partitions_for(
        @name,
        num_partitions: num_partitions,
        timeout: CLUSTER_API_TIMEOUT
      )

      refresh!
    end

    def refresh!
      @topic_metadata = @cluster.fetch_metadata(topics: [@name]).topics.first
      initialize_from_metadata
    end

    def offset_for(partition)
      @cluster.resolve_offset(@name, partition.partition_id, :latest)
    end

    def offsets(partition_ids = nil)
      partition_ids ||= @partitions.map(&:partition_id)
      @cluster.resolve_offsets(@name, partition_ids, :latest)
    end

    def offset_sum
      offsets.values.reduce(:+)
    end

    def consumer_offset_topic?
      name == CONSUMER_OFFSET_TOPIC
    end

    def groups
      @cluster.groups.select do |g|
        g.consumed_topics.include?(self)
      end
    end

    # Needs arguments to be compatible with rails as_json calls
    def as_json(include_config: false, **kwargs)
      json = {
        name: @name,
        replication_factor: @replication_factor,
        partitions: @partitions.sort_by(&:partition_id).map(&:as_json)
      }

      if include_config
        json[:config] = {
          max_message_bytes: max_message_bytes,
          retention_ms: retention_ms,
          retention_bytes: retention_bytes
        }
      end

      json
    end

    def ==(other)
      @name == other.name
    end

    def topic_configs
      @topic_configs ||= describe
    end

    def retention_ms
      topic_configs['retention.ms'].to_i
    end

    def retention_bytes
      topic_configs['retention.bytes'].to_i
    end

    def max_message_bytes
      topic_configs['max.message.bytes'].to_i
    end

    private

    def describe
      @cluster.describe_topic(@name, TOPIC_CONFIGS)
    end

    def initialize_from_metadata
      @name               = @topic_metadata.topic_name
      @partitions         = @topic_metadata.partitions.map { |pm| PartitionWrapper.new(pm, self) }
      @replication_factor = @partitions.map(&:isr).map(&:length).max
    end
  end
end
