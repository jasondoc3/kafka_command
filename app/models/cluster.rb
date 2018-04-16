class Cluster < ApplicationRecord
  has_many :brokers, dependent: :destroy

  validates :name, presence: true
end
