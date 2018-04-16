class Api::V1::BaseController < ApplicationController

  private

  def serialize_json(data)
    if data.is_a?(Array)
      return { data: data, object: 'list' }
    end

    data.as_json.merge(object: data.class.to_s.underscore)
  end

  def render_json(data, status: :ok)
    render json: serialize_json(data), status: status
  end

  def render_errors(errors, status: :unprocessible_entity)
    render json: errors
  end
end
