class Place
  include Mongoid::Document

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
  	f = File.read(file)
  	jsonfile = JSON.parse(f)
  	self.collection.insert_many(jsonfile)
  end 
  
  def self.find_by_short_name(name_str)
  self.collection.find("address_components.short_name" => name_str)
  end
end
