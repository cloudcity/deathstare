module Deathstar
  class ConcurrentInstancesController < ApplicationController
    def show
      if signed_in?
        num = HerokuApp.get_number_running_sidekiq_workers session[:heroku_api_token]
        render json: {actual: num}, status: 200
      elsif Rails.env.development?
        render json: {actual: 1}, status: 200
      else
        render json: {actual: 0}, status: 200
      end
    end

    def update
      if can_control_scalability?
        HerokuApp.scale_sidekiq_workers(session[:heroku_api_token], params[:requested])
        render json: {requested: params[:requested]}, status: 200
      else
        render json: {error: 'Can only scale workers in production environment'}, status: 412
      end
    end

  end
end
