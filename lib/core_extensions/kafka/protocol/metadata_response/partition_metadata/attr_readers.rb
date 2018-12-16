# frozen_string_literal: true

module CoreExtensions
  module Kafka
    module Protocol
      class MetadataResponse
        class PartitionMetadata
          module AttrReaders
            attr_reader :isr, :replicas
          end
        end
      end
    end
  end
end
