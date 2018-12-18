# Kafka Command
A simple Kafka management UI designed for use with Rails.

[![CircleCI](https://circleci.com/gh/jasondoc3/kafka_command.svg?style=svg&circle-token=b30f42578f9568fefa4f28f6d8ecb590feed4ac2)](https://circleci.com/gh/jasondoc3/kafka_command)

## Installation

Add this line to your application's Gemfile

```rb
gem 'kafka_command'
```

## Compatibility ### Rails

Designed for Rails 5. Should work with Rails `4.2`.

### Kafka

Fully compatible with Kafka versions `1.0`, `1.1`, `2.0`, and `2.1`. Limited functionality for `0.11`.

## Usage

Mount KafkaCommand inside your applications `config/routes.rb` file. Make sure it is configured.

```rb
Rails.application.routes.draw do
  mount KafkaCommand::Engine, at: '/kafka'
end
```

## Configuration
Add `kafka_command.yml' to your application's config directory. Kafka command can be configured with multiple Rails environments.

```yaml
development: # Rails environment
  clusters:
    my_cluster: # Cluster name
      description: 'Development Cluster
      version: 1.0
      seed_brokers:
        - localhost:9092
    my_other_cluster: 
      description: 'Development Cluster
      seed_brokers:
        - localhost:9092
production:
  clusters:
    prod:
      version: 1.1
      description: 'Production Cluster'
      seed_brokers: kafka1:9092,kafka2:9093 # Alternate seed brokers configuration
    secondary:
      version: 1.1
      description: 'Secondary Cluster'
      seed_brokers: <%= ENV['SEED_BROKERS']
```

### Cluster configuration options

All of the options below can be provided for each cluster.

#### Required

* `seed_brokers`

#### Optional
* `version`
* `description`
* `socket_timeout`
* `connect_timeout`

#### SSL Authentication
* `ssl_ca_cert` - Required if client cert and key are present.
* `ssl_ca_cert_file_path` - Alternative to ca cert option.
* `ssl_client_cert` - Required if client cert key is present.
* `ssl_client_cert_file_path` - Alternative to client cert option.
* `ssl_client_cert_key` - Required if client cert is present.
* `ssl_client_cert_key_file_path` - Alternative to client cert key option.

#### SASL Authentication
* `sasl_scram_username`
* `sasl_scram_password`

## Functionality

KafkaCommand can manage multiple clusters.

It provides the ability to:

* List Topics
* Create Topics
* Alter topics
  * Adding Partitions (Not supported on Kafka 0.11)
  * Editing basic topic configurations
* Delete topics
* List consumer groups
* List brokers

This project is in an early state, and more functionality is planned for future releases.
