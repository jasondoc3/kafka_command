require_dependency 'app/wrappers/kafka/partition_wrapper'

module Kafka
  class TopicWrapper
    attr_reader :name, :partitions, :replication_factor
    CLUSTER_API_TIMEOUT = 30

    def initialize(topic_metadata, cluster)
      @cluster = cluster
      @topic_metadata = topic_metadata
      initialize_from_metadata
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
      # The offset resolution API will return the offset of the "next" message to
      # be written when resolving the "latest" offset, so we subtract one.
      @cluster.resolve_offset(@name, partition.partition_id, :latest) - 1
    end

    # Needs arguments to be compatible with rails as_json calls
    def as_json(*)
      {
        name: @name,
        replication_factor: @replication_factor,
        partitions: @partitions.sort_by(&:partition_id).map(&:as_json)
      }.with_indifferent_access
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
