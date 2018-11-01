class Placing

attr_accessor :name, :place

def initialize(name, place)
    @name = name
    @place = place
end

def mongoize
    {:name => @name, :place=>@place}
end

def self.mongoize(object) 
    case object
    when Placing then object.mongoize
    when Hash then 
      Placing.new(object[:name], object[:place]).mongoize
    else object
    end
end

def self.demongoize(object)
    case object
    when Hash then Placing.new(object[:name], object[:place])
    when nil then nil
    when placing then object
    end
end

def self.evolve(object)
    case object
    when Placing then object.mongoize
    else object
    end
end


end