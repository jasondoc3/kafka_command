class ClustersController < ApplicationController
  before_action :check_hosts, only: :create

  # GET /clusters
  def index
    @clusters = Cluster.all

    redirection_path = new_cluster_path if @clusters.none?
    render_success(@clusters, redirection_path: redirection_path)
  end

  # GET /clusters/:id
  def show
    @cluster = Cluster.find(params[:id])
    render_success(@cluster)
  end

  # GET /clusters/new
  def new
    @cluster = Cluster.new
  end

  # POST /clusters
  def create
    @cluster = Cluster.new(cluster_params.slice(*cluster_params_keys))
    @cluster.init_brokers(params[:hosts])

    invalid_broker = @cluster.brokers.to_a.find(&:invalid?)
    if invalid_broker
      render_error(invalid_broker.errors, status: 422)
      return
    end

    if @cluster.save
      render_success(
        @cluster,
        status: :created,
        redirection_path: clusters_path,
        flash: { success: 'Cluster created' }
      )
    else
      render_error(@cluster.errors, status: 422)
    end
  end

  # DELETE /clusters/:id
  def destroy
    @cluster = Cluster.find(params[:id])
    @cluster.destroy

    render_success(@cluster, status: :no_content)
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
      render_error('Please specify the hosts', status: 422)
      return
    end
  end
end
