module Kafka
  class ConsumerGroupPartitionWrapper
    attr_reader :lag, :topic_name, :offset, :partition_id, :group_id

    def initialize(lag:, topic_name:, offset:, group_id:, partition_id:)
      @group_id     = group_id
      @lag          = lag
      @topic_name   = topic_name
      @offset       = offset
      @partition_id = partition_id
    end

    def as_json(*)
      {
        lag: @lag,
        offset: @offset,
        partition_id: @partition_id
      }.with_indifferent_access
    end
  end
end
