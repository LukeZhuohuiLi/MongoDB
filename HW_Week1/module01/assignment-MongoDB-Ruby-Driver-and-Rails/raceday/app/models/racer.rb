class Racer
  include Mongoid::Document
  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs
  RACE_COLLECTION = 'racers'
  USERNAME = 'luke'
  PASSWORD = '123456'

def initialize(params={})
       @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
       @number=params[:number].to_i
       @first_name=params[:first_name]
       @last_name=params[:last_name]
       @gender=params[:gender]
       @group=params[:group]
       @secs=params[:secs].to_i
end

  def self.mongo_client
  	client = Mongoid::Clients.default
  	#client.with(user:USERNAME,password:PASSWORD)
  end

  def self.collection
  	self.mongo_client[RACE_COLLECTION]
  end
   
  def self.all(prototype={},sort={:number=>1},skip=0,limit=nil)
       result = self.collection.find(prototype).sort(sort).skip(skip)
       result = result.limit(limit) if !limit.nil?
       return result
  end

  def self.find id
    result = self.collection.find(:_id => id)
    return result.nil? ? nil : Racer.new(result)
  end 
  

end
