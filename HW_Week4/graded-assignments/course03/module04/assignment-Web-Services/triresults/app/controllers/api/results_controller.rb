module Api
  class ResultsController < ApplicationController 

 	def index
 		if !request.accept || request.accept == "*/*"
        render plain: "/api/races/#{params[:race_id]}/results"
      else
      #real implementation ...
        @race = Race.find(params[:race_id])
        @entrants = @race.entrants
        #fresh_when last_modified: @entrants.max(:updated_at)
        #render :index
        if stale? last_modified: @entrants.max(:updated_at)
          render :index
        end
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