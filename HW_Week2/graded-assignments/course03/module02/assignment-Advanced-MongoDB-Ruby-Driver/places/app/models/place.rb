class Place
  include Mongoid::Document
  include ActiveModel::Model
  attr_accessor :id, :formatted_address, :location, :address_components 

  PLACES_COLLECTION = 'places'
  def initialize(params)
  	paramsx = params.deep_symbolize_keys()# “string hash to symbol key hash"
  	@address_components = [] #initialize address component array
    @id = paramsx[:_id].nil? ? paramsx[:id] : paramsx[:_id].to_s #
    @formatted_address = paramsx[:formatted_address]
    @location = Point.new(paramsx[:geometry][:geolocation])
    paramsx[:address_components].each{
    	|component| @address_components << AddressComponent.new(component)
    }
  end 
  def self.mongo_client
  	client = Mongoid::Clients.default
  end
  
  def self.collection
  	self.mongo_client[PLACES_COLLECTION]
  end

  def self.load_all(file)
  	f = File.read(file)# or f = file.read
  	jsonfile = JSON.parse(f)
  	self.collection.insert_many(jsonfile)
  end 
  
  def self.find_by_short_name(name_str)#find view of docs according to the short_name
  self.collection.find("address_components.short_name" => name_str)
  #self.collection.find.aggregate([:$match=>{"address_components.short_name" => name_str} ])
  #failed RSpec test since the limit operation must be inside aggregate()
  end

  def self.to_places(view)
    #Mongo::Collection view to place class object array
  	#temp = []
  	#view.each{|x| temp << Place.new(x)}
  	#return temp
  	view.map{|x| Place.new(x)}
  end

  def self.find(s_id)#return instance of place for a supplied id
  o = self.collection.find(:_id => BSON::ObjectId.from_string(s_id)).first
  if !o.nil?
  Place.new(o)
  else
	nil
  end
  end

  def self.all(offset = 0, limit=nil)#return an instance of all documents as Place instances
  	#temp = []
  	#result = self.collection.find().skip(offset)
  	#result = result.limit(limit) if !limit.nil?
  	#result.each{|x| temp << Place.new(x)}
  	#return temp
    result = self.collection.find().skip(offset)
  	result = result.limit(limit) if !limit.nil?
    result.map{|x| Place.new(x)}
  end

  def self.get_address_components(sort=nil, offset = 0, limit = nil)
  	query_arr = [{:$unwind => "$address_components"}, 
    	        {:$project => {_id:1, address_components:1, formatted_address:1, geometry:{geolocation:1}}}
    	        ]
  if(!sort.nil? && limit.nil?)
  	query_arr = query_arr+[{:$sort => sort},{:$skip => offset}]
  elsif(sort.nil? && !limit.nil?)
  	query_arr = query_arr+[{:$skip => offset},{:$limit => limit}]
  elsif((!sort.nil?) && (!limit.nil?))
  	query_arr = query_arr+[{:$sort => sort},{:$skip => offset},{:$limit => limit}]
  end
  	self.collection.find.aggregate(query_arr)
  end

  def self.get_country_names
  	self.collection.find.aggregate([{:$project => {:_id=>0,address_components:{long_name:1, types:1}}},
  		                            {:$unwind => "$address_components"},
  		                            {:$match =>{:"address_components.types" => "country"}},
  		                            {:$group => {:_id => "$address_components.long_name"}} 
  		                            ]).map{|h| h[:_id]}
  end

  def self.find_ids_by_country_code(country_code)
  	self.collection.find.aggregate([{:$match =>{:"address_components.short_name" => country_code}},
  		                            {:$project => {:_id => 1}}]).map{|doc| doc[:_id].to_s}

  end 
  def self.create_indexes
  	Place.collection.indexes.create_one({:"geometry.geolocation" => Mongo::Index::GEO2DSPHERE})
  end
  def self.remove_indexes
  	Place.collection.indexes.drop_one('geometry.geolocation_2dsphere')
  end

  def self.near(mp, max_meters = nil)
    if !max_meters.nil?
      self.collection.find(
        :"geometry.geolocation" => {:$near =>{
        :$geometry => mp.to_hash,
        :$maxDistance=>max_meters
        } 
        }
      	)
    else
      self.collection.find(
        :"geometry.geolocation" => {:$near =>{
        :$geometry => mp.to_hash
        } 
        }
      	)
       end
 end
  def destroy
  	self.class.collection.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end

  def photos(offset = 0, limit = nil)

  if !limit.nil?
    a = Photo.find_photos_for_place(@id).skip(offset).limit(limit)
  else
    a = Photo.find_photos_for_place(@id).skip(offset)#a will be a view result(cursor/pointer)
  end                                                #not a Photo instance
    if !a.nil?
    a.map{|x| Photo.new(x)}  #re-create Photo instance
    else
    nil
    end
  end

end
