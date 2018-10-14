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

  DEFAULT_EVENTS = {"swim"=>{:order=>0, :name=>"swim", :distance=>1.0, :units=>"miles"},
  "t1"=> {:order=>1, :name=>"t1"},
  "bike"=>{:order=>2, :name=>"bike", :distance=>25.0, :units=>"miles"},
  "t2"=> {:order=>3, :name=>"t2"},
  "run"=> {:order=>4, :name=>"run", :distance=>10.0, :units=>"kilometers"}}
=begin
	
def swim
event=events.select {|event| "swim"==event.name}.first
event||=events.build(DEFAULT_EVENTS["swim"])
end
def swim_order
swim.order
end
def swim_distance
swim.distance
end
def swim_units
swim.units
end
=end

  DEFAULT_EVENTS.keys.each do |name|#swim,t1,bike,t2,run
  		define_method("#{name}") do#def swin or t1...etc
  		event=events.select {|event| name==event.name}.first #event=events.select {|event| "swim"==event.name}.first #get selected event object
  		event||=events.build(DEFAULT_EVENTS["#{name}"])#event||=events.build(DEFAULT_EVENTS["swim"])#build an event object with hash key "#name" if event is nil
  		end
  		["order","distance","units"].each do |prop|
  			if DEFAULT_EVENTS["#{name}"][prop.to_sym]#if hash is not nil
  				define_method("#{name}_#{prop}") do#def swim_order
  				event=self.send("#{name}").send("#{prop}")#event = self.swin.order if prop is :order getter
  				end#self.swin will call the swin method, ".order" will return from the event instance
  				define_method("#{name}_#{prop}=") do |value|#setter
  				event=self.send("#{name}").send("#{prop}=", value)
  				end
  			end
  		end
  end

	def self.default
		Race.new do |race|
		DEFAULT_EVENTS.keys.each {|leg|race.send("#{leg}")}#invoke def swin,bike.etc
		end
	end

	
["city", "state"].each do |action|
     define_method("#{action}") do
     self.location ? self.location.send("#{action}") : nil
     end
     define_method("#{action}=") do |name|
     object=self.location ||= Address.new
     object.send("#{action}=", name)
     self.location=object
     end
end



end
