module KafkaCommand
  class Cluster
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
      :ssl_client_cert_key

    alias_method :id, :name

    delegate :brokers, :topics, :groups, to: :client

    def initialize(name:, seed_brokers:, description: '', protocol: DEFAULT_PROTOCOL)
      @name = name
      @seed_brokers = seed_brokers
      @client = initialize_client
      @description = description
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

    def self.find(cluster_name)
      all.find { |c| c.name == cluster_name }
    end

    def self.none?
      all.none?
    end

    def self.all
      @clusters ||=
        begin
          KafkaCommand.config['clusters'].map do |cluster|
            cluster_name = cluster.keys.first
            cluster_info = cluster.values.first

            new(
              name: cluster_name,
              seed_brokers: cluster_info['seed_brokers'],
              protocol: cluster_info['protocol'],
              description: cluster_info['description']
            )
          end
        end
    end

    def ssl?
      ssl_ca_cert.present? &&
        ssl_client_cert.present? &&
        ssl_client_cert_key.present?
    end

    def sasl?
      sasl_scram_username.present? && sasl_scram_password.present?
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
            client_kwargs[:ssl_ca_cert] = ssl_ca_cert
          elsif ssl?
            client_kwargs[:ssl_ca_cert] = ssl_ca_cert
            client_kwargs[:ssl_client_cert] = ssl_client_cert
            client_kwargs[:ssl_client_cert_key] = ssl_client_cert_key
            client_kwargs
          end

          ClientWrapper.new(**client_kwargs, logger: Rails.logger)
        end
      end
  end
end
