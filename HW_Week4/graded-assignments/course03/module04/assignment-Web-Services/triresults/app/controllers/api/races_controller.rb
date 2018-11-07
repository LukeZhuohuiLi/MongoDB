module Api
  class RacesController < ApplicationController 

   rescue_from Mongoid::Errors::DocumentNotFound do |exception|
      @msg = "woops: cannot find race[#{params[:id]}]"
      if !request.accept || request.accept == "*/*"
        render plain: @msg, status: :not_found
      else
        render action: :error, status: :not_found, content_type: "#{request.accept}"
      
      end
    end

     rescue_from ActionView::MissingTemplate do |exception|
      render plain: "woops: we do not support that content-type[#{request.accept}]", :status => 415
    end

    def index
      if !request.accept || request.accept == "*/*"
        render plain: "/api/races, offset=[#{params[:offset]}], limit=[#{params[:limit]}]"
      else
      end
    end

    # def show
    #   if !request.accept || request.accept == "*/*"
    #     render plain: "/api/races/#{params[:id]}"
    #   else
    #     @race = Race.find(params[:id])
    #     case request.accept
    #     when "application/xml" then render xml: @race
    #     when "application/json" then render json: @race
    #     end
    #   end
    # end
    def show
	if !request.accept || request.accept == "*/*"
		render plain: "/api/races/#{params[:id]}"
	elsif (request.accept.include? "application/xml") || (request.accept.include? "application/json") then
		@race = Race.find(params[:id])
		render "race", content_type: "#{request.accept}"
	end
   end

    def create
      if !request.accept || request.accept == "*/*" 
        render plain: "#{params[:race][:name]}", status: :ok
      else
       @race = Race.new(race_params)
        if @race.save
          render plain: race_params[:name], status: :created
        else
          render json: @race.errors
        end
      end
    end

    def update
      Rails.logger.debug("method=#{request.method}")
      @race = Race.find(params[:id])
      if @race.update(race_params)
        render json: @race
      else
        render json: @race.errors
      end
    end

    def destroy
      @race = Race.find(params[:id])
      @race.destroy
      render :nothing=>true, :status => :no_content
    end

    private
      def race_params
        params.require(:race).permit(:name, :date)
      end
    end
end
