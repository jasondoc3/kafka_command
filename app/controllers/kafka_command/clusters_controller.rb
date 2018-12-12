require_dependency 'kafka_command/application_controller'

module KafkaCommand
  class ClustersController < ApplicationController
    # GET /clusters
    def index
      @clusters = Cluster.all

      flash[:search] = params[:name]

      if params[:name].present?
        @clusters = @clusters.select do |c|
          regex = /#{params[:name]}/i
          c.name.match?(regex)
        end
      end

      redirection_path = new_cluster_path if Cluster.none?
      render_success(@clusters, redirection_path: redirection_path, flash: flash.to_hash)
    end

    # GET /clusters/:id
    def show
      @cluster = Cluster.find(params[:id])

      if @cluster
        render_success(@cluster)
      else
        record_not_found
      end
    end

    private
    # leave for config validation

    def cluster_params
      params.permit(*cluster_params_keys)
    end

    def cluster_params_keys
      [:name, :description, :version]
    end
  end
end
