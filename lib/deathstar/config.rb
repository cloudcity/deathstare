module Deathstar
  class Config
    # @return [String] Heroku Application ID
    attr_accessor :heroku_app_id

    # @return [String] Heroku OAuth ID
    attr_accessor :heroku_oauth_id

    # @return [String] Heroku OAuth Secret
    attr_accessor :heroku_oauth_secret
  end
end
