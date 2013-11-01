module Deathstare
  class BaseController < ApplicationController
    include Deathstare::CurrentUser

    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception

    # This shouldn't be happening any more--> we try to refresh tokens if they're expired or about to expire
    rescue_from HerokuApiV3::ExpiredTokenError, with: :token_expired

    force_ssl if: -> { Rails.env.production? }
    before_action :ensure_signed_in!, except: :not_signed_in # production only

    def not_signed_in
      redirect_to root_path if signed_in?
    end

    protected

    def token_expired
      session[:user_id] = nil
      respond_to do |fmt|
        fmt.html { redirect_to not_signed_in_path, alert: 'Heroku session has expired. Please sign in.' }
        fmt.json { render json: {error: 'Heroku session has expired. Please sign in.'}, status: 401 }
      end
    end

    def can_control_scalability?
      Rails.env.production?
    end

    private

    def ensure_signed_in!
      if !signed_in? && Rails.env.production?
        respond_to do |fmt|
          fmt.html { redirect_to not_signed_in_path, alert: 'Please sign in.' }
          fmt.json { render json: {error: 'Heroku session has expired. Please sign in.'}, status: 401 }
        end
      end
    end
  end
end
