class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from Kafka::ConnectionError, with: :kafka_connection_error
  rescue_from Kafka::ClusterAuthorizationFailed, with: :kafka_authorization_error

  protected

  def record_not_found
    render_error('Not Found', status: :not_found)
  end

  def kafka_connection_error
    error_msg = 'Could not connect to Kafka with the specified brokers'
    render_error(
      error_msg,
      status: 500,
      flash: { error: error_msg }
    )
  end

  def kafka_authorization_error
    error_msg = 'You are not authorized to perform that action'
    render_error(
      error_msg,
      status: 401,
      flash: { error: error_msg }
    )
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

  def render_error(data, status: :unprocessible_entity, flash: {})
    respond_to do |format|
      format.html do
        redirect_back fallback_location: root_path, flash: flash and return if flash.present?

        case status
        when :not_found, 404
          render file: 'public/404.html', status: status, layout: false
        else
          render file: 'public/500.html', status: status, layout: false
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
end
