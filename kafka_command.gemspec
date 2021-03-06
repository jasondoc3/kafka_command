# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'kafka_command/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'kafka_command'
  s.version     = KafkaCommand::VERSION
  s.authors     = ['jasondoc3']
  s.email       = ['jasondoc3@gmail.com']
  s.homepage    = 'https://github.com/jasondoc3/kafka_command'
  s.summary     = 'A simple Kafka management UI.'
  s.description = 'A simple Kafka management UI.'
  s.license     = 'MIT'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'exe'
  s.require_paths = ['lib']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '>= 4'
  s.add_dependency 'ruby-kafka', '> 0.6.3'
  s.add_dependency 'rails-ujs'
end
