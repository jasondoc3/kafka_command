require 'forwardable'
require_dependency 'app/models/kafka_command/client'

module KafkaCommand
  class Cluster
    extend Forwardable
    DEFAULT_PROTOCOL = 'PLAINTEXT'

    attr_reader :client,
      :name,
      :description,
      :seed_brokers,
      :protocol,
      :sasl_scram_username,
      :sasl_scram_password,
      :ssl_ca_cert_file_path,
      :ssl_client_cert_file_path,
      :ssl_client_cert_key_file_path,
      :version

    alias_method :id, :name

    def_delegators :@client, :topics, :groups, :brokers

    def initialize(name:, seed_brokers:, description: nil, protocol: DEFAULT_PROTOCOL,
                   sasl_scram_username: nil, sasl_scram_password: nil, ssl_ca_cert_file_path: nil,
                   ssl_client_cert_file_path: nil, ssl_client_cert_key_file_path: nil, version: nil
                  )
      @name = name
      @seed_brokers = seed_brokers
      @description = description
      @sasl_scram_username = sasl_scram_username
      @sasl_scram_password = sasl_scram_password
      @ssl_ca_cert_file_path = ssl_ca_cert_file_path
      @ssl_client_cert_file_path = ssl_client_cert_file_path
      @ssl_client_cert_key_file_path = ssl_client_cert_key_file_path
      @version = version
      @client = initialize_client
    end

    def connected?
      # Tried using all?(&:connected?) here, but was getting some weird behavior with the views
      brokers.map(&:connected?).all?
    end

    def create_topic(name, **kwargs)
      client.create_topic(name, **kwargs)
      client.refresh_topics!
      topics.find { |t| t.name == name }
    end

    def to_human
      name.humanize.capitalize
    end

    def to_s
      name
    end

    def ssl?
      ssl_ca_cert_file_path.present? &&
        ssl_client_cert_file_path.present? &&
        ssl_client_cert_key_file_path.present?
    end

    def sasl?
      sasl_scram_password.present? && sasl_scram_password.present?
    end

    def ==(other)
      name == other.name
    end

    def self.find(cluster_name)
      all.find { |c| c.name == cluster_name }
    end

    def self.none?
      all.none?
    end

    def self.count
      all.count
    end

    def self.all
      KafkaCommand.config['clusters'].map do |cluster|
        cluster_name = cluster.keys.first
        cluster_info = cluster.values.first

        new(
          name: cluster_name,
          seed_brokers: cluster_info['seed_brokers'],
          protocol: cluster_info['protocol'],
          description: cluster_info['description'],
          sasl_scram_username: cluster_info['sasl_scram_username'],
          sasl_scram_password: cluster_info['sasl_scram_password'],
          ssl_ca_cert_file_path: cluster_info['ssl_ca_cert_file_path'],
          ssl_client_cert_file_path: cluster_info['ssl_client_cert_file_path'],
          ssl_client_cert_key_file_path: cluster_info['ssl_client_cert_key_file_path']
        )
      end
    end

    private

      def initialize_client
        @client ||= begin
          client_kwargs = {
            brokers: seed_brokers,
            client_id: name
          }

          if sasl?
            client_kwargs[:sasl_scram_username] = sasl_scram_username
            client_kwargs[:sasl_scram_password] = sasl_scram_password
            client_kwargs[:sasl_scram_mechanism] = 'sha256'
            client_kwargs[:ssl_ca_cert] = File.read(ssl_ca_cert_file_path).strip
          elsif ssl?
            client_kwargs[:ssl_ca_cert] = File.read(ssl_ca_cert_file_path).strip
            client_kwargs[:ssl_client_cert] = File.read(ssl_client_cert_file_path).strip
            client_kwargs[:ssl_client_cert_key] = File.read(ssl_client_cert_key_file_path).strip
          end

          Client.new(**client_kwargs)
        end
      end
  end
end
