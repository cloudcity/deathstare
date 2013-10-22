module Deathstar
  class EndPointsController < ApplicationController
    def index
      @end_points = EndPoint.all
    end

    def reset
      end_point.clear_cached_devices
      flash[:notice] = "Cleared cache of devices and sessions for #{end_point.base_url}."
      redirect_to end_points_path
    end

    private

    def end_point
      EndPoint.find params[:id]
    end
  end
end
