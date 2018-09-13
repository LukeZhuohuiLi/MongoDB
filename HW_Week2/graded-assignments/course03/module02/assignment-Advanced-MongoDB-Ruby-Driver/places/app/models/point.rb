class Point
  attr_accessor :longitude, :latitude

  def initialize(params)
  	new_params = params.symbolize_keys()
    if new_params[:type]
      @longitude = new_params[:coordinates][0]
      @latitude = new_params[:coordinates][1]
    else
      @longitude = new_params[:lng]
      @latitude = new_params[:lat]
    end
  end

  def to_hash
    {:type=>"Point",:coordinates=>[@longitude, @latitude]}
  end

end