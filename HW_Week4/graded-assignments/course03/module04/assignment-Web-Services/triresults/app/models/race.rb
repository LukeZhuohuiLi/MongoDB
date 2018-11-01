class Race
  include Mongoid::Document
  include Mongoid::Timestamps
  field :n, as: :name, type: String
  field :date, as: :date, type: Date
  field :loc, as: :location, type: Address
  field :next_bib, as: :next_bib, type: Integer, default: 0

  embeds_many :events, order: [:order.asc], as: :parent
  has_many :entrants, foreign_key: "race._id",dependent: :delete, order: [:secs.asc, :bib.asc]
  #entrants->race(class:RaceRef)->_id
  
  scope :upcoming, -> { where(:date.gte => Date.current)}
  scope :past, -> { where(:date.lt => Date.current)}

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
  				define_method("#{name}_#{prop}=") do |value|#setter  def swim_order=
  				event=self.send("#{name}").send("#{prop}=", value)#self.swim.order = value
  				end
  			end
  		end
  end

	def self.default
		Race.new do |race|#create a list of default events for a new Race object
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

  def next_bib
   self[:next_bib] = self.inc(next_bib: 1)[:next_bib]#[:next_bib] to avoid an infinite loop within next_bib method
   #self.inc(next_bib: 1) Performs an atomic $inc on the field.
   #https://docs.mongodb.com/mongoid/master/tutorials/mongoid-persistence/#atomic
   #self[:next_bib] = self[:next_bib] + 1#not going to work for rspec spec/service_facade_spec.rb -e rq03
  end

  def get_group racer
  	if racer && racer.birth_year && racer.gender
  		quotient=(date.year-racer.birth_year)/10
  		min_age=quotient*10
  		max_age=((quotient+1)*10)-1
  		gender=racer.gender
  		name=min_age >= 60 ? "masters #{gender}" : "#{min_age} to #{max_age} (#{gender})"
  		Placing.demongoize(:name=>name)
  	end
  end

  def create_entrant racer
  	entrant = Entrant.new
  	entrant.race = self.attributes.symbolize_keys.slice(:_id, :n, :date)
  	entrant.racer = racer.info.attributes
  	entrant.group = self.get_group(racer)
  	events.each do |event|
  		if event
  			entrant.send("#{event.name}=", event)
  		end
  	end
  	entrant.validate
  	if entrant.valid?
  		entrant.bib = next_bib
  		entrant.save
  	end
  	return entrant
  end

  def self.upcoming_available_to racer
  	nilArray = []
  	race_ids = racer.races.pluck(:race).map {|r| r[:_id]}#"not.method" will not affect object query to DB
  	a = Race.upcoming.first#"not.method" will affect class query to DB, the actual DB query will look like Race.past.first
  	b = Race.past.first#Race.upcoming.first
  	if((a.nil? == false) && (b.nil? == false))
  		if(a.date > b.date)
  			self.upcoming.not_in(:id => race_ids)
  		else
       	self.upcoming.in(:id => race_ids)#for "not.method" same as self.past.not_in(:id => race_ids)
       end
   elsif((a.nil? == true) && (b.nil? == false))
  	   if(b.date < Date.current)#"not." is not added, since a is nil, no upcoming available
  	   	nilArray
  	   else#upcoming available, b.date>date.current means "not." is added, no past available
  	   	nilArray
  	   end
  	elsif((a.nil? == false) && (b.nil? == true))
  	 	if(a.date > Date.current)#"not" is not added, upcoming available
  	 		self.upcoming.not_in(:id => race_ids)
  	    else#a.date < Date.current, "not" is added, past available
  	    	self.upcoming.in(:id => race_ids)
  	    end
  	elsif((a.nil? == true) && (b.nil? == true))
  		nilArray
  	end

#
#upcoming_race_ids = racer.races.upcoming.pluck(:race).map {|r| r[:_id]}
#self.upcoming.not_in(:id => upcoming_race_ids)
#irb(main):907:0> Race.not.upcoming_available_to(racer).where(:name=>{:$regex=>"A2"}).pluck(:name,:date)

# upcoming_race_ids = racer.races.upcoming.pluck(:race).map {|r| r[:_id]}
# D, [2018-10-17T12:22:59.005315 #9080] DEBUG -- : MONGODB | localhost:27017 | triresults_development.find | STARTED | {"find"=>"results", "filter"=>{"racer.racer_id"=>BSON::ObjectId('5bc6b102ea846f237802d1be'), "race.date"=>{"$gte"=>2018-10-17 00:00:00 UTC}}, "sort"=>{"race.date"=>-1}, "projection"=>{"race"=>1}, "lsid"=>{"id"=><BSON::Binary:0x62078100 type=uuid data=...
# D, [2018-10-17T12:22:59.016316 #9080] DEBUG -- : MONGODB | localhost:27017 | triresults_development.find | SUCCEEDED | 0.011s

#self.upcoming.not_in(:id => upcoming_race_ids)
# D, [2018-10-17T12:22:59.017302 #9080] DEBUG -- : MONGODB | localhost:27017 | triresults_development.find | STARTED | {"find"=>"races", "filter"=>{"date"=>{"$not"=>{"$gte"=>2018-10-17 00:00:00 UTC}}, "_id"=>{"$not"=>{"$nin"=>[BSON::ObjectId('5bc6b165ea846f237802d1bf')]}}, "n"=>{"$regex"=>"A2"}}, "projection"=>{"n"=>1, "date"=>1}, "lsid"=>{"id"=><BSON::Binary:0x620781...
# D, [2018-10-17T12:22:59.029561 #9080] DEBUG -- : MONGODB | localhost:27017 | triresults_development.find | SUCCEEDED | 0.011s

end
  # race1: Race _id: 5bc4fba7ea846f0bdccfc0a8
  # race2: Race _id: 5bc4fbacea846f0bdccfc0a9
  # race3: Race _id: 5bc4fbc8ea846f0bdccfc0ab
  # race2.create_entrant racer
  # race2.entrants.each{|e| pp e}   Entrant _id: 5bc4fbb5ea846f0bdccfc0aa 
  # Racer _id: 5bc4eb79ea846f0bdccfc0a3 
  #
  #upcoming_race_ids = racer.races.upcoming.pluck(:race).map {|r| r[:_id]}
  #find all id of races in parent object "racer" where race.date greater than or equal to today
  #will return id of race2
  #
  #
  #Race.in(arrays of ids) will return Race objects according to (arrays of ids)
  #Race.not_in(arrays of ids) will return all other Race objects except objects where id = (arrays of ids) 
  #
  #
  #self.upcoming.not_in(:id => upcoming_race_ids) is equivalent to Race.upcoming.not_in(:id => upcoming_race_ids)
  #which will return all other upcoming Race objects except the race objects with upcoming_race_ids:5bc4fbacea846f0bdccfc0a9
  #
  #Race.upcoming_available_to(racer).where(:name=>{:$regex=>"A2"}).pluck(:name,:date,:id)
  #[["Thinking About It A2", 2018-11-15 00:00:00 UTC, BSON::ObjectId('5bc4fbc8ea846f0bdccfc0ab')]]
  #
  #Race.upcoming_available_to(racer).where(:name=>{:$regex=>"A2"}).pluck(:name,:date,:id)
  #For irb console:
  #upcoming_race_ids = racer.races.upcoming.pluck(:race).map {|r| r[:_id]}
  #Race.upcoming.not_in(:id => upcoming_race_ids).where(:name=>{:$regex=>"A2"}).pluck(:name,:date,:id)
  # [["Thinking About It A2", 2018-11-15 00:00:00 UTC, BSON::ObjectId('5bc4fbc8ea846f0bdccfc0ab')]]
  #
  #
  #got a bug when testing Race.not.upcoming_available_to(racer).where(:name=>{:$regex=>"A2"}).pluck(:name,:date)
  #Result is a nil array []
  #It can pass the rspec test if I use "not." for upcoming_available_to method
  #
  #
  #
  #
  #
  #
  #For "not."
  #upcoming will be "not=>upcoming", but it also change ".in" to "not=>in" and "not_in" to "not=>not_in"
  #which causes wrong output result.
  #Actual MongoDB query for not.upcoming_available_to, self.upcoming.not_in it's actually 
  #"filter"=>{"date"=>{"$not"=>{"$gte"=>2018-10-17 00:00:00 UTC}}, "_id"=>{"$not"=>{"$nin"=>[]}}
  #
  #
  #
  #
  #
end
