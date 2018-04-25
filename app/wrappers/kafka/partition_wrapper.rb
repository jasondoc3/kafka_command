require 'forwardable'

module Kafka
  class PartitionWrapper
    extend Forwardable
    def_delegators :@partition_metadata, :isr, :leader, :partition_id, :replicas

    def initialize(partition_metadata)
      @partition_metadata = partition_metadata
    end

    def as_json(*)
      {
        isr: isr,
        leader: leader,
        number: partition_id
      }.with_indifferent_access
    end

    # TODO
    #
    # implement describe to retrieve important configs
    # def describe
    # end
  end
end
