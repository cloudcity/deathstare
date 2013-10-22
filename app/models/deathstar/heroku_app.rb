module Deathstar
  class HerokuApp

    # @abstract Heroku doesn't reject people from logging in even if they aren't members on the app
    #   They'll get an API token anyway. However, every subsequent call to the API fails with a 403
    #   (forbidden) -- that's how we can tell they're not a legit user.
    # @param token [String]
    def self.token_valid? token
      HerokuApiV3.get(token: token, url: "/apps/#{DEATHSTAR_HEROKU_APP_ID}")
      true
    rescue HerokuApiV3::UnauthorizedAppError
      false
    end

    # @param token [String] valida Heroku OAuth token
    # @param requested [Integer or String] Number of sidekiq workers requested
    def self.scale_sidekiq_workers(token, requested)
      HerokuApiV3.patch(
        token: token,
        url: "/apps/#{DEATHSTAR_HEROKU_APP_ID}/formation/sidekiq",
        body: {quantity: requested}
      )
    end

    # @param token [String] valida Heroku OAuth token
    # @return [Integer] Number of sidekiq processes in "up" state
    def self.get_number_running_sidekiq_workers(token)
      # Sadly the formation API doesn't give us the status
      # And the dyno API won't let us query by type :-(
      # So we get all dynos and filter in Ruby
      dynos = HerokuApiV3.get(
        token: token,
        url: "/apps/#{DEATHSTAR_HEROKU_APP_ID}/dynos"
      )
      dynos.count { |dyno| dyno['type'] == 'sidekiq' && dyno['state'] == 'up' }
    end
  end
end
