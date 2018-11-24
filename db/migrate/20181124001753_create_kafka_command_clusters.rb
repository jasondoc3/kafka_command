class CreateKafkaCommandClusters < ActiveRecord::Migration[5.2]
  def change
    create_table :kafka_command_clusters do |t|
      t.string :name
      t.string :version
      t.text :description
      t.string :sasl_scram_username
      t.string :encrypted_sasl_scram_password
      t.string :encrypted_sasl_scram_password_iv
      t.string :sasl_scram_mechanism
      t.string :encrypted_ssl_ca_cert
      t.string :encrypted_ssl_ca_cert_iv
      t.string :encrypted_ssl_client_cert
      t.string :encrypted_ssl_client_cert_iv
      t.string :encrypted_ssl_client_cert_key
      t.string :encrypted_ssl_client_cert_key_iv
      t.timestamps
    end
  end
end
