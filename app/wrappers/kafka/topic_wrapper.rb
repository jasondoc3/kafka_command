module Kafka
  class TopicWrapper
    attr_reader :name, :partitions, :replication_factor

    def initialize(topic_metadata, cluster)
      @cluster = cluster
      initialize_from_metadata(topic_metadata)
    end

    def destroy
      @cluster.delete_topic(@name, timeout: ClusterWrapper::CLUSTER_API_TIMEOUT)
    end

    def set_partitions!(num_partitions)
      @cluster.create_partitions_for(
        @name,
        num_partitions: num_partitions,
        timeout: ClusterWrapper::CLUSTER_API_TIMEOUT
      )

      refresh!
    end

    def refresh!
      topic_metadata = @cluster.fetch_metadata(topics: [@name]).topics.first
      initialize_from_metadata(topic_metadata)
    end

    def as_json(*)
      {
        name: @name,
        replication_factor: @replication_factor,
        partitions: @partitions.map(&:as_json)
      }.with_indifferent_access
    end

    private

    def initialize_from_metadata(topic_metadata)
      @name = topic_metadata.topic_name
      @partitions = topic_metadata.partitions.map { |pm| PartitionWrapper.new(pm) }
      @replication_factor = @partitions.map(&:isr).map(&:length).max
    end
  end
end
