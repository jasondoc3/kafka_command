$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "kafka_command/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kafka_command"
  s.version     = KafkaCommand::VERSION
  s.authors     = ["jasondoc3"]
  s.email       = ["jasondoc3@gmail.com"]
  s.homepage    = ""
  s.summary     = "Summary of Kafka Command."
  s.description = "Description of Kafka Command."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"
  s.add_dependency "ruby-kafka", "~> 0.6.8"
  s.add_dependency "attr_encrypted"

  s.add_development_dependency "sqlite3"
end
