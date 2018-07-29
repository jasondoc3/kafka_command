require_dependency 'app/wrappers/kafka/partition_wrapper'

module Kafka
  class TopicWrapper
    attr_reader :name, :partitions, :replication_factor
    alias_method :id, :name
    CLUSTER_API_TIMEOUT = 30
    CONSUMER_OFFSET_TOPIC = '__consumer_offsets'.freeze

    def initialize(topic_metadata, cluster)
      @cluster = cluster
      @topic_metadata = topic_metadata
      initialize_from_metadata
    end

    def brokers_spread
      ((replication_factor.to_f / @cluster.brokers.count.to_f) * 100).round
    end

    def destroy
      @cluster.delete_topic(@name, timeout: CLUSTER_API_TIMEOUT)
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
      @name == CONSUMER_OFFSET_TOPIC
    end

    def groups
      @cluster.groups.select do |g|
        g.consumed_topics.include?(self)
      end
    end

    # Needs arguments to be compatible with rails as_json calls
    def as_json(*)
      {
        name: @name,
        replication_factor: @replication_factor,
        partitions: @partitions.sort_by(&:partition_id).map(&:as_json)
      }
    end

    def ==(other)
      @name == other.name
    end

    private

    def initialize_from_metadata
      @name = @topic_metadata.topic_name
      @partitions = @topic_metadata.partitions.map do |pm|
        PartitionWrapper.new(pm, self)
      end

      @replication_factor = @partitions.map(&:isr).map(&:length).max
    end
  end
end
