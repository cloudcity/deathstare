require 'omniauth'
require 'omniauth-heroku'
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :heroku,
    Deathstare.config.heroku_oauth_id,
    Deathstare.config.heroku_oauth_secret,
    scope: :write
end
