class BrokersController < ApplicationController
  # GET /clusters/:cluster_id/brokers
  def index
    @brokers = Broker.where(cluster_id: params[:cluster_id]).all
    render_success(@brokers)
  end

  # GET /clusters/:cluster_id/brokers/:id
  def show
    @broker = Broker.find(params[:id])
    render_success(@broker)
  end
end