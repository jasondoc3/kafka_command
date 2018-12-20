# frozen_string_literal: true

module KafkaCommand
  class ApplicationController < ActionController::Base
    protect_from_forgery unless: -> { request.format.json? }

    rescue_from Kafka::ConnectionError, with: :kafka_connection_error
    rescue_from Kafka::ClusterAuthorizationFailed, with: :kafka_authorization_error
    rescue_from UnsupportedApiError, with: :unsupported_api_error

    before_action :check_config

    protected

      def unsupported_api_error(exception)
        render_error(exception.message, status: 422)
      end

      def record_not_found
        render_error('Not Found', status: :not_found)
      end

      # Handle this error separately
      def kafka_connection_error
        flash[:error] = 'Could not connect to Kafka with the specified brokers'
        render 'kafka_command/application/error', status: 500
      end

      def kafka_authorization_error
        render_error('You are not authorized to perform that action', status: 401)
      end

      def serialize_json(data, **kwargs)
        if data.is_a?(ActiveRecord::Relation) || data.is_a?(Array)
          return {
            data: data.map { |d| d.as_json(**kwargs) }
          }
        end

        data.as_json(**kwargs)
      end

      def render_success(data, status: :ok, redirection_path: nil, flash: {}, **kwargs)
        respond_to do |format|
          format.html do
            redirect_to redirection_path, flash: flash if redirection_path
          end

          format.json do
            if status == :no_content || status.to_s.to_i == 204
              head :no_content
            else
              render_json(data, status: status, **kwargs)
            end
          end
        end
      end

      def render_error(data, status: :unprocessible_entity)
        respond_to do |format|
          format.html do
            if Rails::VERSION::MAJOR >= 5
              redirect_back(fallback_location: error_path, flash: { error: data })
            else
              redirect_to :back, flash: { error: data }
            end
          end

          format.json { render_json_errors(data, status: status) }
        end
      end

      def render_json(data, status:, **kwargs)
        render json: serialize_json(data, **kwargs), status: status
      end

      def render_json_errors(errors, status: :unprocessible_entity)
        render json: errors, status: status
      end

      def check_config
        if KafkaCommand.config.blank?
          flash[:error] = 'Kafka command is not configured'
          render 'kafka_command/configuration_error'
          return
        end

        unless KafkaCommand.config.valid?
          flash[:error] = KafkaCommand.config.errors.join("\n")
          render 'kafka_command/configuration_error'
        end
      end
  end
end
