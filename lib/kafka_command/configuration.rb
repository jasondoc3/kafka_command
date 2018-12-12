module KafkaCommand
  def self.config=(config_hash)
    @config ||= Configuration.new(config_hash)
  end

  def self.config
    @config
  end

  class ConfigurationError < StandardError; end

  class Configuration
    HOST_REGEX = /[^\:]+:[0-9]{1,5}/
    attr_reader :config_hash, :clusters

    CLUSTER_KEYS = %w(
      protocol
      description
      version
      seed_brokers
      ssl_ca_cert
      ssl_ca_cert_file_path
      ssl_client_cert
      ssl_client_cert_file_path
      ssl_client_cert_key
      ssl_client_cert_key_file_path
      sasl_scram_username
      sasl_scram_password
    )

    def initialize(config_hash)
      @config_hash = config_hash[ENV['RAILS_ENV']]
      raise ConfigurationError, 'No config specified for environment' if @config_hash.blank?

      @clusters = @config_hash['clusters']
      validate!
    end

    def validate!
      validate_clusters
    end

    private

      def validate_clusters
        raise ConfigurationError, 'Clusters must be provided' if clusters.blank?

        clusters.each do |_, cluster_hash|
          validate_cluster(cluster_hash)
        end
      end

      def validate_cluster(cluster)
        cluster.keys.each do |key|
          raise ConfigurationError, "Invalid cluster option, #{key}" unless CLUSTER_KEYS.include?(key)
        end

        raise ConfigurationError, 'Must specify a list of seed brokers' if cluster['seed_brokers'].blank?

        cluster['seed_brokers'].each do |broker|
          validate_broker(broker)
        end

        validate_ssl(cluster)
        validate_sasl(cluster)
      end

      def validate_broker(broker)
        unless broker.match?(HOST_REGEX)
          raise ConfigurationError, 'Broker must be a valid host/portname combination'
        end
      end

      def validate_ssl(cluster)
        if client_cert(cluster).present? && client_cert_key(cluster).blank?
          raise ConfigurationError, 'KafkaCommand initialized with `ssl_client_cert` but no `ssl_client_cert_key`. Please provide both.'
        elsif client_cert(cluster).blank? && client_cert_key(cluster).present?
          raise ConfigurationError, 'KafkaCommand initialized with `ssl_client_cert_key`, but no `ssl_client_cert`. Please provide both.'
        end
      end

      def validate_sasl(cluster)
        if cluster['sasl_scram_username'].present? && cluster['sasl_scram_password'].blank?
          raise ConfigurationError, 'KafkaCommand initialized with `sasl_scram_username` but no `sasl_scram_password`. Please provide both.'
        elsif cluster['sasl_scram_username'].blank? && cluster['sasl_scram_password'].present?
          raise ConfigurationError, 'KafkaCommand initialized with `sasl_scram_password` but no `sasl_scram_username`. Please provide both.'
        end
      end

      def client_cert(cluster)
        cluster['ssl_client_cert'] ||

        if cluster['ssl_client_cert_file_path'] && File.exists?(cluster['ssl_client_cert_file_path'])
          cluster['ssl_client_cert_file_path']
        end
      end

      def client_cert_key(cluster)
        cluster['ssl_client_cert_key']

        if cluster['ssl_client_cert_key_file_path'] && File.exists?(cluster['ssl_client_cert_key_file_path'])
          cluster['ssl_client_cert_key_file_path']
        end
      end
  end
end
