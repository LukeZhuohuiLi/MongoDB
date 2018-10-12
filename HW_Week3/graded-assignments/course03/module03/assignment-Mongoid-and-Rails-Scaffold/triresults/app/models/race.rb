class Race
  include Mongoid::Document
  include Mongoid::Timestamps
  field :n, as: :name, type: String
  field :date, as: :date, type: Date
  field :loc, as: :location, type: Address

  embeds_many :events, order: [:order.asc], as: :parent
  
  has_many :entrants, foreign_key: "race._id",dependent: :delete, order: [:secs.asc, :bib.asc]

  #entrants->race(class:RaceRef)->_id
  
  scope :upcoming, -> {where(:date.gte => Date.current)}
  scope :past, -> {where(:date.lt => Date.current)}

  

end
