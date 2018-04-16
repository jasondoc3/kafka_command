class Broker < ApplicationRecord
  belongs_to :cluster

  validates :host, presence: true
  validates :port, presence: true
end
