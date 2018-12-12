require 'yaml'

config_file_path = "#{Rails.root}/config/kafka_command.yml"

if File.exists?(config_file_path)
  KafkaCommand.config = YAML.load(ERB.new(File.read(config_file_path)).result(binding))
  puts KafkaCommand.config.errors if KafkaCommand.config.invalid?
else
  puts "kafka_command.yml not found. KafkaCommand not configured via a yml file."
end
