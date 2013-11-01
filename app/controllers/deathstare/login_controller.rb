module Deathstare
  class LoginController < BaseController

    skip_before_action :ensure_signed_in!, except: :destroy

    def new
      redirect_to '/auth/heroku'
    end

    def create
      omniauth = request.env['omniauth.auth']
      @current_user = User.find_or_create_by!(oauth_provider: omniauth['provider'], uid: omniauth['uid'])
      @current_user.token = omniauth['credentials']['token']
      @current_user.token_expires_at = !!omniauth['credentials']['expires'] ? Time.at(omniauth['credentials']['expires_at']) : nil
      @current_user.refresh_token = omniauth['credentials']['refresh_token']
      @current_user.save!
      if HerokuApp.user_authorized_for_app?(@current_user)
        session[:user_id] = @current_user.id
        redirect_to root_path, notice: 'Signed in with Heroku'
      else
        @current_user.authorized_for_app = false
        @current_user = nil
        session[:user_id] = nil
        redirect_to root_path, alert: "You are not authorized on this app. If you're a member of Cloud City Development, talk to the administrator."
      end
    end

    def destroy
      @current_user = nil
      session[:user_id] = nil
      redirect_to root_path, notice: 'Ended Heroku OAuth Session'
    end
  end
end
