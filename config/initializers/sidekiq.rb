if ENV['RAILS_ENV'] == 'production'
  Sidekiq.configure_server do |config|
    config.redis = { :url => ENV['REDIS_PROVIDER'], :namespace => 'deathstar' }
  end
  
  Sidekiq.configure_client do |config|
    config.redis = { :url => ENV['REDIS_PROVIDER'], :namespace => 'deathstar' }
  end
end
