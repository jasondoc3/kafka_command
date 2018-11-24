module KafkaCommand
  class Engine < ::Rails::Engine
    isolate_namespace KafkaCommand

    initializer "kafka_command.assets.precompile" do |app|
      app.config.assets.precompile += %w( kafka_command/* )
    end
  end
end
