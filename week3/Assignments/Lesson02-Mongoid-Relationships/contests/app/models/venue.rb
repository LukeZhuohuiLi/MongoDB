class Venue
  include Mongoid::Document
  field :name, type: String

  embeds_one :address, as: :addressable, class_name: 'Address'
  has_many :contests, dependent: :restrict
end
