class Point
	attr_accessor :longitude, :latitude

def initialize(lg, la)
	@longitude = lg
	@latitude = la
end

 #accepts no arguments and marshals the state of the instance
  #into MongoDB format as a Ruby hash
def mongoize
	{:type => 'Point', :coordinates => [@longitude, @latitude]}
end

def self.demongoize(object)
    case object
    when Hash then
    	Point.new(object[:coordinates][0],object[:coordinates][1])
    when nil
    	nil
    end
end



end