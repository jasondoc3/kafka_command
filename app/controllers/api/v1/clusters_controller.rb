class Api::V1::ClustersController < Api::V1::BaseController

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

    if cluster.save
      render_json(cluster, status: :created)
    else
      render_errors(cluster.errors)
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

end
