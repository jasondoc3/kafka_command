class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from Kafka::ConnectionError, with: :kafka_connection_error

  private

  def record_not_found
    render_error('Not Found', status: :not_found)
  end

  def kafka_connection_error
    render_error('Could not connect to Kafka with the specified brokers', status: 500)
  end

  def serialize_json(data)
    if data.is_a?(ActiveRecord::Relation) || data.is_a?(Array)
      return { data: data }
    end

    data.as_json
  end

  def render_success(data, status: :ok)
    respond_to do |format|
      format.html
      format.json do
        if status == :no_content || status.to_s.to_i == 204
          head :no_content
        else
          render_json(data, status: status)
        end
      end
    end
  end

  def render_error(data, status: :unprocessible_entity)
    respond_to do |format|
      format.html
      format.json { render_json_errors(data, status: status) }
    end
  end

  def render_json(data, status:)
    render json: serialize_json(data), status: status
  end

  def render_json_errors(errors, status: :unprocessible_entity)
    render json: errors, status: status
  end
end
