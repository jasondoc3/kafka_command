module Kafka
  class TopicWrapper
    CLUSTER_API_TIMEOUT = 5
    attr_reader :name, :partitions, :replication_factor

    def initialize(topic_metadata, cluster)
      @cluster = cluster
      @name = topic_metadata.topic_name
      @partitions = topic_metadata.partitions.map { |pm| PartitionWrapper.new(pm) }
      @replication_factor = @partitions.map(&:isr).map(&:length).max
    end

    def destroy
      @cluster.delete_topic(@name, timeout: CLUSTER_API_TIMEOUT)
    end

    def as_json(*)
      {
        name: @name,
        replication_factor: @replication_factor,
        partitions: @partitions.map(&:as_json)
      }.with_indifferent_access
    end
  end
end
