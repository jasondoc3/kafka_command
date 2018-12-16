# frozen_string_literal: true

require 'yaml'

config_file_path = "#{Rails.root}/config/kafka_command.yml"

if File.exists?(config_file_path)
  KafkaCommand::Configuration.load!(config_file_path)
else
  puts 'kafka_command.yml not found. KafkaCommand not configured via a yml file.'
end
