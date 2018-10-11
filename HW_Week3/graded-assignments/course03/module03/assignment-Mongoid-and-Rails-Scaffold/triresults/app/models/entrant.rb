class Entrant
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in collection: "results"
  field :bib,as: :bib, type: Integer
  field :secs,as: :secs, type: Float
  field :o, as: :overall, type: Placing
  field :gender, as: :gender, type: Placing
  field :group, as: :group, type: Placing

  embeds_many :results, class_name: 'LegResult', order: [:"event.o".asc], after_add: :update_total

  def update_total(result)
  	self.secs = 0
  	self.results.each do |result|
    if result.secs.nil? == false
    	self.secs = self.secs + result.secs
    end
    end
  end

end
