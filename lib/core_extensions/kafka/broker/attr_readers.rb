# frozen_string_literal: true

module CoreExtensions
  module Kafka
    module Broker
      module AttrReaders
        attr_reader :host, :port, :node_id
      end
    end
  end
end
