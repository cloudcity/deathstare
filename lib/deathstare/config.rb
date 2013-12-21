module Deathstare
  class Config
    # @return [String] Heroku Application ID
    attr_accessor :heroku_app_id

    # @return [String] Heroku OAuth ID
    attr_accessor :heroku_oauth_id

    # @return [String] Heroku OAuth Secret
    attr_accessor :heroku_oauth_secret

    # @return [String] Librato email address
    attr_accessor :librato_email

    # @return [String] Librato token
    attr_accessor :librato_api_token

    # @return [Array<String>] Allowable end point base URLs
    attr_accessor :target_urls

    # @return [Class] Subclass of {Deathstare::UpstreamSession}
    attr_accessor :upstream_session_type

    def initialize
      @target_urls = []
    end
  end
end
