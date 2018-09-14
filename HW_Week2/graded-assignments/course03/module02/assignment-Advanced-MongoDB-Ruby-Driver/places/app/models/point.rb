class Point
  attr_accessor :longitude, :latitude

  def initialize(params)
  	new_params = params.symbolize_keys()#convert from string_value format to key_value hash format
    if new_params[:type]
      @longitude = new_params[:coordinates][0]
      @latitude = new_params[:coordinates][1]
    else
      @longitude = new_params[:lng]
      @latitude = new_params[:lat]
    end
  end

  def to_hash#convert the coordinate to GeoJSON point hash
    {:type=>"Point",:coordinates=>[@longitude, @latitude]}#GeoJSON Point hash
  end

end