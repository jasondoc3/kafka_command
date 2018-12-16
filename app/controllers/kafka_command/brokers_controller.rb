# frozen_string_literal: true

require_dependency 'kafka_command/application_controller'

module KafkaCommand
  class BrokersController < ApplicationController
    # GET /clusters/:cluster_id/brokers
    def index
      @cluster = Cluster.find(params[:cluster_id])
      @brokers = @cluster.brokers
      render_success(@brokers)
    end

    # GET /clusters/:cluster_id/brokers/:id
    def show
      cluster = Cluster.find(params[:cluster_id])
      @broker = cluster.brokers.find { |b| b.node_id == params[:id].to_i }

      if @broker.present?
        render_success(@broker)
      else
        record_not_found
      end
    end
  end
end
