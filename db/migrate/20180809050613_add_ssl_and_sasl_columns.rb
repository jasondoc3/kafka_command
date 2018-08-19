class AddSslAndSaslColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :clusters, :sasl_scram_username, :string
    add_column :clusters, :encrypted_sasl_scram_password, :string
    add_column :clusters, :encrypted_sasl_scram_password_iv, :string
    add_column :clusters, :sasl_scram_mechanism, :string
    add_column :clusters, :encrypted_ssl_ca_cert, :text
    add_column :clusters, :encrypted_ssl_ca_cert_iv, :string
    add_column :clusters, :encrypted_ssl_client_cert, :text
    add_column :clusters, :encrypted_ssl_client_cert_iv, :string
    add_column :clusters, :encrypted_ssl_client_cert_key, :text
    add_column :clusters, :encrypted_ssl_client_cert_key_iv, :string
  end
end
