require 'forwardable'

class Broker < ApplicationRecord
  extend Forwardable
  def_delegator :cluster, :client
  belongs_to :cluster

  validates :host, presence: true, uniqueness: true
end
