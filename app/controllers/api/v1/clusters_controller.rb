class Api::V1::ClustersController < Api::V1::BaseController
  before_action :check_hosts, only: :create

  # GET /api/v1/clusters
  def index
    render_json(Cluster.all)
  end

  # GET /api/v1/clusters/:id
  def show
    cluster = Cluster.find(params[:id])
    render_json(cluster)
  end

  # POST /api/v1/clusters
  def create
    cluster = Cluster.new(cluster_params.slice(*cluster_params_keys))
    cluster.init_brokers(params[:hosts])

    invalid_broker = cluster.brokers.to_a.find(&:invalid?)
    if invalid_broker
      render_errors(invalid_broker.errors, status: 422)
      return
    end

    if cluster.save
      render_json(cluster, status: :created)
    else
      render_errors(cluster.errors, status: 422)
    end
  end

  # DELETE /api/v1/clusters/:id
  def destroy
    cluster = Cluster.find(params[:id])
    cluster.destroy

    head :no_content
  end

  private

  def cluster_params
    params.permit(*cluster_params_keys)
  end

  def cluster_params_keys
    [:name, :description, :version]
  end

  def check_hosts
    if params[:hosts].blank?
      render_errors('Please specify the hosts', status: 422)
      return
    end
  end
end
