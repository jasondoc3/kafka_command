class Api::V1::BaseController < ApplicationController

  private

  def serialize_json(data)
    if data.is_a?(ActiveRecord::Relation) || data.is_a?(Array)
      return { data: data }
    end

    data.as_json
  end

  def render_json(data, status: :ok)
    render json: serialize_json(data), status: status
  end

  def render_errors(errors, status: :unprocessible_entity)
    render json: errors, status: status
  end

end
