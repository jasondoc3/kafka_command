require 'yaml'

puts "HERE"
config_file_path = "#{Rails.root}/config/kafka_command.yml"

if File.exists?(config_file_path)
  KafkaCommand.config = YAML.load(File.read(config_file_path))
  KafkaCommand.config.validate!
else
  puts "kafka_command.yml not found. KafkaCommand not configured via a yml file."
end
