# frozen_string_literal: true

require 'forwardable'

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
      :ssl_ca_cert,
      :ssl_client_cert,
      :ssl_client_cert_key,
      :version

    alias_method :id, :name

    def_delegators :@client, :topics, :groups, :brokers

    def initialize(name:, seed_brokers:, description: nil, protocol: DEFAULT_PROTOCOL,
                   sasl_scram_username: nil, sasl_scram_password: nil, ssl_ca_cert_file_path: nil,
                   ssl_client_cert_file_path: nil, ssl_client_cert_key_file_path: nil, version: nil,
                   ssl_ca_cert: nil, ssl_client_cert: nil, ssl_client_cert_key: nil
                  )
      @name = name
      @seed_brokers = seed_brokers
      @description = description
      @sasl_scram_username = sasl_scram_username
      @sasl_scram_password = sasl_scram_password
      @ssl_ca_cert = ssl_ca_cert
      @ssl_ca_cert_file_path = ssl_ca_cert_file_path
      @ssl_client_cert = ssl_client_cert
      @ssl_client_cert_file_path = ssl_client_cert_file_path
      @ssl_client_cert_key = ssl_client_cert_key
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
      get_ssl_ca_cert.present?
    end

    def sasl?
      sasl_scram_username.present? && sasl_scram_password.present?
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
      KafkaCommand.config.clusters.map do |name, cluster_info|
        new(
          name: name,
          seed_brokers: cluster_info['seed_brokers'],
          protocol: cluster_info['protocol'],
          description: cluster_info['description'],
          sasl_scram_username: cluster_info['sasl_scram_username'],
          sasl_scram_password: cluster_info['sasl_scram_password'],
          ssl_ca_cert: cluster_info['ssl_ca_cert'],
          ssl_ca_cert_file_path: cluster_info['ssl_ca_cert_file_path'],
          ssl_client_cert: cluster_info['ssl_client_cert'],
          ssl_client_cert_file_path: cluster_info['ssl_client_cert_file_path'],
          ssl_client_cert_key: cluster_info['ssl_client_cert_key'],
          ssl_client_cert_key_file_path: cluster_info['ssl_client_cert_key_file_path']
        )
      end
    end

    private

      def get_ssl_ca_cert
        return @ssl_ca_cert if @ssl_ca_cert

        if @ssl_ca_cert_file_path && File.exists?(@ssl_ca_cert_file_path)
          File.read(@ssl_ca_cert_file_path).strip
        end
      end

      def get_ssl_client_cert
        return @ssl_client_cert if @ssl_client_cert

        if @ssl_client_cert_file_path && File.exists?(@ssl_client_cert_file_path)
          File.read(@ssl_client_cert_file_path).strip
        end
      end

      def get_ssl_client_cert_key
        return @ssl_client_cert_key if @ssl_client_cert_key

        if @ssl_client_cert_key_file_path && File.exists?(@ssl_client_cert_key_file_path)
          File.read(@ssl_client_cert_key_file_path).strip
        end
      end

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
            client_kwargs[:ssl_ca_cert] = get_ssl_ca_cert
          elsif ssl?
            client_kwargs[:ssl_ca_cert] = get_ssl_ca_cert
            client_kwargs[:ssl_client_cert] = get_ssl_client_cert
            client_kwargs[:ssl_client_cert_key] = get_ssl_client_cert_key
          end

          Client.new(**client_kwargs)
        end
      end
  end
end
