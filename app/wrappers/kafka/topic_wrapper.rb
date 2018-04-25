module Kafka
  class TopicWrapper
    attr_reader :name, :partitions, :replication_factor

    def initialize(topic_metadata)
      @name = topic_metadata.topic_name
      @partitions = topic_metadata.partitions.map { |pm| PartitionWrapper.new(pm) }
      @replication_factor = @partitions.map(&:isr).map(&:length).max
    end
  end
end
