class Api::V1::BrokersController < Api::V1::BaseController
  # GET /api/v1/clusters/:cluster_id/brokers
  def index
    brokers = Broker.where(cluster_id: params[:cluster_id]).all
    render_json(brokers)
  end

  # GET /api/v1/clusters/:cluster_id/brokers/:id
  def show
    broker = Broker.find(params[:id])
    render_json(broker)
  end
end
