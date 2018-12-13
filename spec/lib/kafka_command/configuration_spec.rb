RSpec.describe KafkaCommand::Configuration do
  subject { described_class.new(config_hash) }

  describe '#valid?' do
    context 'valid' do
      let(:config_hash) { YAML.load(File.read('spec/dummy/config/kafka_command.yml')) }

      it 'returns true' do
        expect(subject.valid?).to eq(true)
        expect(subject.errors).to be_empty
      end

      context 'ssl' do
        context 'no file paths' do
          let(:config_hash) { YAML.load(File.read('spec/fixtures/files/kafka_command_ssl.yml')) }

          it 'returns true' do
            expect(subject.valid?).to eq(true)
            expect(subject.errors).to be_empty end
        end

        context 'file paths' do
          let(:config_hash) { YAML.load(File.read('spec/fixtures/files/kafka_command_ssl_file_paths.yml')) }

          it 'returns true' do
            expect(subject.valid?).to eq(true)
            expect(subject.errors).to be_empty
          end
        end
      end

      context 'sasl' do
        let(:config_hash) { YAML.load(File.read('spec/fixtures/files/kafka_command_sasl.yml')) }

        it 'returns true' do
          expect(subject.valid?).to eq(true)
          expect(subject.errors).to be_empty
        end
      end
    end

    context 'invalid' do
      context 'wrong environment' do
        let(:config_hash) { YAML.load(File.read('spec/fixtures/files/kafka_command_staging.yml')) }
        let(:env) { 'staging' }

        before do
          expect(env).to_not eq(ENV['RAILS_ENV'])
        end

        it 'returns false' do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).to include('No config specified for environment')
        end
      end

      context 'no clusters' do
        let(:config_hash) do
          {
            'test' => {
              'test_cluster' => {
                'seed_brokers' => ['localhost:9092']
              }
            }
          }
        end

        it 'returns false' do
          expect(subject.valid?).to eq(false)
          expect(subject.errors).to include('Cluster must be provided')
        end
      end

      context 'invalid clusters' do
        context 'bad cluster option' do
          let(:config_hash) do
            {
              'test' => {
                'clusters' => {
                  'test_cluster' => {
                    'bad_option' => 'bad',
                    'seed_brokers' => ['localhost:9092']
                  }
                }
              }
            }
          end

          it 'returns false' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to include('Invalid cluster option, bad_option')
          end
        end

        context 'no seed brokers' do
          let(:config_hash) do
            {
              'test' => {
                'clusters' => {
                  'test_cluster' => {
                    'description' => 'production cluster'
                  }
                }
              }
            }
          end

          it 'returns false' do
            expect(subject.valid?).to eq(false)
            expect(subject.errors).to include('Must specify a list of seed brokers')
          end

          context 'bad host/port combination' do
            let(:config_hash) do
              {
                'test' => {
                  'clusters' => {
                    'test_cluster' => {
                      'seed_brokers' => ['badhost'],
                    }
                  }
                }
              }
            end

            it 'returns false' do
              expect(subject.valid?).to eq(false)
              expect(subject.errors).to include('Broker must be a valid host/port combination')
            end
          end
        end

        context 'sasl' do
          context 'username and no password' do
            let(:config_hash) do
              {
                'test' => {
                  'clusters' => {
                    'test_cluster' => {
                      'seed_brokers' => ['localhost:9092'],
                      'sasl_scram_username' => 'jason'
                    }
                  }
                }
              }
            end

            it 'returns false' do
              expect(subject.valid?).to eq(false)
              expect(subject.errors).to include('Initialized with `sasl_scram_username` but no `sasl_scram_password`. Please provide both.')
            end
          end

          context 'password and no username' do
            let(:config_hash) do
              {
                'test' => {
                  'clusters' => {
                    'test_cluster' => {
                      'seed_brokers' => ['localhost:9092'],
                      'sasl_scram_password' => 'jason'
                    }
                  }
                }
              }
            end

            it 'returns false' do
              expect(subject.valid?).to eq(false)
              expect(subject.errors).to include('Initialized with `sasl_scram_password` but no `sasl_scram_username`. Please provide both.')
            end
          end
        end

        context 'ssl' do
          context 'no file paths' do
            context 'client, no client key' do
              let(:config_hash) do
                {
                  'test' => {
                    'clusters' => {
                      'test_cluster' => {
                        'seed_brokers' => ['localhost:9092'],
                        'ssl_ca_cert' => 'test_ca_cert',
                        'ssl_client_cert' => 'test_client_cert'
                      }
                    }
                  }
                }
              end

              it 'returns false' do
                expect(subject.valid?).to eq(false)
                expect(subject.errors).to include('Initialized with `ssl_client_cert` but no `ssl_client_cert_key`. Please provide both.')
              end
            end

            context 'client key, no client' do
              let(:config_hash) do
                {
                  'test' => {
                    'clusters' => {
                      'test_cluster' => {
                        'seed_brokers' => ['localhost:9092'],
                        'ssl_ca_cert' => 'test_ca_cert',
                        'ssl_client_cert_key' => 'test_client_cert_key'
                      }
                    }
                  }
                }
              end

              it 'returns false' do
                expect(subject.valid?).to eq(false)
                expect(subject.errors).to include('Initialized with `ssl_client_cert_key`, but no `ssl_client_cert`. Please provide both.')
              end
            end

            context 'with client and key, no certificate authority' do
              let(:config_hash) do
                {
                  'test' => {
                    'clusters' => {
                      'test_cluster' => {
                        'seed_brokers' => ['localhost:9092'],
                        'ssl_client_cert' => 'test_client_cert',
                        'ssl_client_cert_key' => 'test_client_cert_key'
                      }
                    }
                  }
                }
              end

              it 'returns false' do
                expect(subject.valid?).to eq(false)
                expect(subject.errors).to include('Cannot provide client certificate/key without a certificate authority')
              end
            end
          end

          context 'file paths' do
            context 'client, no client key' do
              let(:config_hash) do
                {
                  'test' => {
                    'clusters' => {
                      'test_cluster' => {
                        'seed_brokers' => ['localhost:9092'],
                        'ssl_ca_cert_file_path' => 'test_ca_cert',
                        'ssl_client_cert_file_path' => 'test_client_cert'
                      }
                    }
                  }
                }
              end

              it 'returns false' do
                expect(subject.valid?).to eq(false)
                expect(subject.errors).to include('Initialized with `ssl_client_cert` but no `ssl_client_cert_key`. Please provide both.')
              end
            end

            context 'client key, no client' do
              let(:config_hash) do
                {
                  'test' => {
                    'clusters' => {
                      'test_cluster' => {
                        'seed_brokers' => ['localhost:9092'],
                        'ssl_ca_cert_file_path' => 'test_ca_cert',
                        'ssl_client_cert_key_file_path' => 'test_client_cert_key'
                      }
                    }
                  }
                }
              end

              it 'returns false' do
                expect(subject.valid?).to eq(false)
                expect(subject.errors).to include('Initialized with `ssl_client_cert_key`, but no `ssl_client_cert`. Please provide both.')
              end
            end

            context 'with client and key, no certificate authority' do
              let(:config_hash) do
                {
                  'test' => {
                    'clusters' => {
                      'test_cluster' => {
                        'seed_brokers' => ['localhost:9092'],
                        'ssl_client_cert_file_path' => 'test_client_cert',
                        'ssl_client_cert_key_file_path' => 'test_client_cert_key'
                      }
                    }
                  }
                }
              end

              it 'returns false' do
                expect(subject.valid?).to eq(false)
                expect(subject.errors).to include('Cannot provide client certificate/key without a certificate authority')
              end
            end
          end
        end
      end
    end
  end
end
