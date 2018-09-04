class Racer
   include Mongoid::Document
   include ActiveModel::Model
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
    result = self.collection.find(:_id=>BSON::ObjectId.from_string(id)).first
    return result.nil? ? nil : Racer.new(result)
  end 
  
  def save
  	result = self.class.collection
  	             .insert_one(number:@number,first_name:@first_name,last_name:@last_name, gender:@gender, group:group, secs:@secs)
    @id = result.inserted_id
  end

  def update(params)
  @number = params[:number].to_i
  @first_name = params[:first_name]
  @last_name = params[:last_name]
  @secs = params[:secs].to_i
  @gender = params[:gender]
  @group = params[:group]
  #delete other key and value, params will only have specified key and value.
  params.slice!(:number, :first_name, :last_name, :gender, :group, :secs) if !params.nil?
  self.class.collection
            .find(:_id => BSON::ObjectId.from_string(@id))
            .update_one(params)
  end

  def destroy
    self.class.collection.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end
  def updated_at
    nil
  end

  def self.paginate(params)
    page = (params[:page] ||=1).to_i
    limit = (params[:per_page] ||=30).to_i
    skip = (page - 1)*limit
    sort = params[:sort] ||= {:number => 1}
    racers = []

    all({},sort,skip,limit).each do |doc|
      racers << Racer.new(doc)
    end
    
      total=all({},sort,0,1).count
      WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
      end
  end

  def to_s
    "#{@id},number #{@number}, #{@first_name}, #{@last_name},#{@gender},#{@group},secs=#{@secs}"
  end
   
end
