module Deathstar
  class HerokuApp

    # @abstract Heroku doesn't reject people from logging in even if they aren't members on the app
    #   They'll get an API token anyway. However, every subsequent call to the API fails with a 403
    #   (forbidden) -- that's how we can tell they're not a legit user.
    # @param user [User] -- authenticated User with Heroku OAuth token and/or refresh token
    def self.user_authorized_for_app? user
      HerokuApiV3.get(user: user, url: "/apps/#{Deathstar.config.heroku_app_id}")
      true
    rescue HerokuApiV3::UnauthorizedAppError
      false
    end

    # @param user [User] -- authenticated User with Heroku OAuth token and/or refresh token
    # @param requested [Integer or String] Number of sidekiq workers requested
    def self.scale_sidekiq_workers(user, requested)
      HerokuApiV3.patch(
        user: user,
        url: "/apps/#{Deathstar.config.heroku_app_id}/formation/sidekiq",
        body: {quantity: requested}
      )
    end

    # @param user [User] -- authenticated User with Heroku OAuth token and/or refresh token
    # @return [Integer] Number of sidekiq processes in "up" state
    def self.get_number_running_sidekiq_workers(user)
      # Sadly the formation API doesn't give us the status
      # And the dyno API won't let us query by type :-(
      # So we get all dynos and filter in Ruby
      dynos = HerokuApiV3.get(
        user: user,
        url: "/apps/#{Deathstar.config.heroku_app_id}/dynos"
      )
      dynos.count { |dyno| dyno['type'] == 'sidekiq' && dyno['state'] == 'up' }
    end
  end
end
