require 'yaml'

config_file_path = "#{Rails.root}/config/kafka_command.yml"

if File.exists?(config_file_path)
  KafkaCommand.config = YAML.load(File.read(config_file_path))[ENV['RAILS_ENV']]
else
  puts "kafka_command.yml not found. KafkaCommand not configured."
end
