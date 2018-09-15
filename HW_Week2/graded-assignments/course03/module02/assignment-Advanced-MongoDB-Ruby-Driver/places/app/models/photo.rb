class Photo
  
  attr_accessor :id, :location, :place
  attr_writer :contents

  def initialize(params = nil)
  	if !params.nil?
  	@id = params[:_id].nil? ? params[:id] : params[:_id].to_s 
  	@location = Point.new(params[:metadata][:location])
  	@place =
    end
  end


  def self.mongo_client
  	client = Mongoid::Clients.default
  end


  def persisted?
    !@id.nil?
  end


  def save
    if !persisted? 
  	gps = EXIFR::JPEG.new(@contents).gps  
  	@location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
  	@contents.rewind
  	description ={}
    description[:content_type] = "image/jpeg"
    description[:metadata] = {:location => @location.to_hash, :place => @place}
  	grid_file = Mongo::Grid::File.new(@contents.read, description)
  	id=self.class.mongo_client.database.fs.insert_one(grid_file)
  	@id = id.to_s	
    else
    self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).
     update_one(:metadata => {:location => @location.to_hash, :place => @place })
     #the find command returns a "pointer"
     #or view "cursor" for us to update the document
     #use find.first will cause error because it is the acutual content  
     #doc = self.class.mongo_client.database.fs.find(
     #  '_id': BSON::ObjectId.from_string(@id)
     #).first
     # doc[:metadata][:place] = @place
     # doc[:metadata][:location] = @location.to_hash
     #self.class.mongo_client.database.fs.find(
     # '_id': BSON::ObjectId.from_string(@id)
     # ).update_one(doc)
    end                                                                                                  
  end                                                       


  def self.all(offset = 0, limit = nil)
  	if limit.nil?
     a = self.mongo_client.database.fs.find.skip(offset)
    else
     a = self.mongo_client.database.fs.find.skip(offset).limit(limit)
    end
     a.map{|doc| Photo.new(doc)}
  end


  def self.find(id)
  	a = self.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(id)).first
  	a.nil? ? nil : Photo.new(a)
  end


 def contents
  	f = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id))
  	if f
  		buffer = ""
  		f.chunks.reduce([]) do |x,chunk|
  			buffer << chunk.data.data
  		end
  	 return buffer
  	end
  end
  
 def destroy
 	f = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id))
    self.class.mongo_client.database.fs.delete_one(f)
    #or 
    #self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one
 end

 
 def find_nearest_place_id(maximum_distance)
     Place.near(@location, maximum_distance).limit(1).projection(:_id => true).first["_id"]
 end

 def place

 end
end
