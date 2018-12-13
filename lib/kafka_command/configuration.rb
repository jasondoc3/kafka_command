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
    attr_reader :config, :clusters, :errors

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
      @config = config_hash[ENV['RAILS_ENV']]
      @clusters = config['clusters'] if config.present?
      @errors = []
    end

    def valid?
      @errors = []

      if config.blank?
        errors << 'No config specified for environment'
        return false
      end

      validate!
      errors.none?
    end

    private

      def validate!
        validate_clusters
      rescue => e
        errors << 'Kafka Command is configured incorrectly'
      end

      def validate_clusters
        if clusters.blank?
          errors << 'Cluster must be provided'
          return
        end

        clusters.each do |_, cluster_hash|
          validate_cluster(cluster_hash)
        end
      end

      def validate_cluster(cluster)
        cluster.keys.each do |key|
          unless CLUSTER_KEYS.include?(key)
            errors << "Invalid cluster option, #{key}"
            return
          end
        end

        if cluster['seed_brokers']&.compact.blank?
          errors << 'Must specify a list of seed brokers'
          return
        end

        cluster['seed_brokers'].each do |broker|
          validate_broker(broker)
        end

        validate_ssl(cluster)
        validate_sasl(cluster)
      end

      def validate_broker(broker)
        unless broker&.match?(HOST_REGEX)
          errors << 'Broker must be a valid host/port combination'
        end
      end

      def validate_ssl(cluster)
        ca_cert         = certificate_authority(cluster)
        client_cert     = client_certificate(cluster)
        client_cert_key = client_certificate_key(cluster)

        if ca_cert
          if client_cert && !client_cert_key
            errors << 'Initialized with `ssl_client_cert` but no `ssl_client_cert_key`. Please provide both.'
          elsif !client_cert && client_cert_key
            errors << 'Initialized with `ssl_client_cert_key`, but no `ssl_client_cert`. Please provide both.'
          end
        elsif client_cert || client_cert_key
          errors << 'Cannot provide client certificate/key without a certificate authority'
        end
      end

      def validate_sasl(cluster)
        if cluster['sasl_scram_username'].present? && cluster['sasl_scram_password'].blank?
          errors << 'Initialized with `sasl_scram_username` but no `sasl_scram_password`. Please provide both.'
        elsif cluster['sasl_scram_username'].blank? && cluster['sasl_scram_password'].present?
          errors << 'Initialized with `sasl_scram_password` but no `sasl_scram_username`. Please provide both.'
        end
      end

      def certificate_authority(cluster)
        cluster['ssl_ca_cert'] || cluster['ssl_ca_cert_file_path']
      end

      def client_certificate(cluster)
        cluster['ssl_client_cert'] || cluster['ssl_client_cert_file_path']
      end

      def client_certificate_key(cluster)
        cluster['ssl_client_cert_key'] || cluster['ssl_client_cert_key_file_path']
      end
  end
end
