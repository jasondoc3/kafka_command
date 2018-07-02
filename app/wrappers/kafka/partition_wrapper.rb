require 'forwardable'

module Kafka
  class PartitionWrapper
    extend Forwardable
    attr_reader :topic
    def_delegators :@partition_metadata, :isr, :leader, :partition_id, :replicas

    def initialize(partition_metadata, topic)
      @topic = topic
      @partition_metadata = partition_metadata
    end

    def highwater_mark_offset
      @topic.offset_for(self)
    end
    alias offset highwater_mark_offset

    def as_json(*)
      {
        isr: isr,
        leader: leader,
        id: partition_id,
        highwater_mark_offset: offset
      }
    end

    # TODO
    #
    # implement describe to retrieve important configs
    # def describe
    # end
  end
end
