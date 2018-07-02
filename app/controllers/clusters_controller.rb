class ClustersController < ApplicationController
  before_action :check_hosts, only: :create

  # GET /clusters
  def index
    @clusters = Cluster.all
    render_success(@clusters)
  end

  # GET /clusters/:id
  def show
    @cluster = Cluster.find(params[:id])
    render_success(@cluster)
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
      render_success(@cluster, status: :created)
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
