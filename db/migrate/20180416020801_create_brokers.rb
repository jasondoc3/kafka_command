class CreateBrokers < ActiveRecord::Migration[5.2]
  def change
    create_table :brokers do |t|
      t.string :host
      t.integer :kafka_broker_id
      t.references :cluster, index: true

      t.timestamps
    end
  end
end
