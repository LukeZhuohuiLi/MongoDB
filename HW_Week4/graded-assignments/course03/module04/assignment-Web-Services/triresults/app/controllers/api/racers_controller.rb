module Api
  class RacersController < ApplicationController 

 	def index
 	if !request.accept || request.accept == "*/*"
      render plain: "/api/racers/#{params[:racer_id]}/entries"
      else
      #real implementation ...
      end
 	end

 	def show

 	end

 	def create

 	end

 	def update

 	end

 	def destroy

 	end

 	private


 end
end