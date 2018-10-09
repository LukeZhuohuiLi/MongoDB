class Entrant
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "results"
  field :bib,as: :bib, type: Integer
  field :secs,as: :secs, type: Float
  field :o, as: :overall, type: Placing
  field :gender, as: :gender, type: Placing
  field :group, as: :group, type: Placing

  embeds_many :results, class_name: 'LegResult',order: [:""]
  embeds_one :event, polymorphic: true, as: :parent

end
