require 'omniauth'
require 'omniauth-heroku'
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :heroku,
    Deathstar.config.heroku_oauth_id,
    Deathstar.config.heroku_oauth_secret,
    scope: :write
end
