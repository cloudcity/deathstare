module Deathstar
  class LoginController < ApplicationController

    skip_before_action :ensure_signed_in!, except: :destroy

    def new
      redirect_to '/auth/heroku'
    end

    def create
      token = request.env['omniauth.auth']['credentials']['token']
      if HerokuApp.token_valid?(token)
        session[:heroku_api_token] = request.env['omniauth.auth']['credentials']['token']
        redirect_to root_path, notice: 'Signed in with Heroku'
      else
        session[:heroku_api_token] = nil
        redirect_to root_path, alert: "You are not authorized on this app. If you're a member of Cloud City Development, talk to the administrator."
      end
    end

    def destroy
      session[:heroku_api_token] = nil
      redirect_to root_path, notice: 'Ended Heroku OAuth Session'
    end
  end
end
