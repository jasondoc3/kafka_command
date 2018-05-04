module Requests
  module JsonHelper
    def json
      JSON.parse(response.body)
    end
  end
end

RSpec.configure do |config|
  config.include(Requests::JsonHelper)
end
