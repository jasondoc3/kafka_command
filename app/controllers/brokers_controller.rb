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
      @broker = Broker.find(params[:id])
      render_success(@broker)
    end
  end
end
