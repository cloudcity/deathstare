module Deathstar
  module CurrentUser
    extend ActiveSupport::Concern

    included do
      attr_reader :current_user
      helper_method :signed_in?, :current_user
    end

    def signed_in?
      if session[:user_id].present?
        @current_user ||= User.find(session[:user_id])
        true
      else
        false
      end
    end
  end
end