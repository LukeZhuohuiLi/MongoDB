class Point
    
  attr_accessor :longitude, :latitude

def initialize(lng, lat)
    @longitude = lng
    @latitude = lat
end

 #accepts no arguments and marshals the state of the instance
  #into MongoDB format as a Ruby hash
def mongoize
	{:type => 'Point', :coordinates => [@longitude, @latitude]}
end

#takes in all forms of the object and produces a DB-friendly form
def self.mongoize(object)
    case object
    when Point then object.mongoize
    when Hash then 
      if object[:type] 
          Point.new(object[:coordinates][0], object[:coordinates][1]).mongoize
      else       
          Point.new(object[:lng], object[:lat]).mongoize
      end
    else object
    end
end

#accepts a single argument of at least three (3) forms – nil,
#class instance, and database hash form – and returns an instance of the class
def self.demongoize(object)
    case object
    when Hash then
        Point.new(object[:coordinates][0],object[:coordinates][1])
    when Point then object
    when nil then nil
    end
end

#used by criteria to convert object to DB-friendly form
def self.evolve(object)
    case object
    when Point then object.mongoize
    else object
    end
end

end