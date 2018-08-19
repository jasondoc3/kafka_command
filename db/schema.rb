# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_09_050613) do

  create_table "brokers", force: :cascade do |t|
    t.string "host"
    t.integer "kafka_broker_id"
    t.integer "cluster_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cluster_id"], name: "index_brokers_on_cluster_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.string "name"
    t.string "version"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sasl_scram_username"
    t.string "encrypted_sasl_scram_password"
    t.string "encrypted_sasl_scram_password_iv"
    t.string "sasl_scram_mechanism"
    t.text "encrypted_ssl_ca_cert"
    t.string "encrypted_ssl_ca_cert_iv"
    t.text "encrypted_ssl_client_cert"
    t.string "encrypted_ssl_client_cert_iv"
    t.text "encrypted_ssl_client_cert_key"
    t.string "encrypted_ssl_client_cert_key_iv"
  end

end
