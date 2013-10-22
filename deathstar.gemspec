$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "deathstar/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "deathstar"
  s.version     = Deathstar::VERSION
  s.authors     = ['Wolfram Arnold', 'Zack Hobson']
  s.email       = ['wolfram@rubyfocus.biz']
  s.homepage    = 'http://rubygems.org/gems/deathstar'
  s.summary     = 'Distributed Load Test Framework with Heroku and Librato'
  s.description = 'Send death rays into your app and see if the empire will crush it.'

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "Procfile"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'rails', '~> 4.0.0'
  s.add_dependency 'sass-rails', '~> 4.0.0'
  s.add_dependency 'uglifier', '>= 1.3.0'
  s.add_dependency 'coffee-rails', '~> 4.0.0'
  s.add_dependency 'jquery-rails', '~> 3.0.4'
  s.add_dependency 'bootstrap-sass-rails', '~> 3.0.0.2'
  s.add_dependency 'will_paginate', '~> 3.0.4'
  s.add_dependency 'haml', '~> 4.0.3'
  s.add_dependency 'yard'
  s.add_dependency 'faraday', '~> 0.8.8'
  s.add_dependency 'typhoeus', '~> 0.6.5'
  s.add_dependency 'librato-metrics', '~> 1.1.1'
  s.add_dependency 'faker', '~> 1.2.0'
  s.add_dependency 'sidekiq', '~> 2.14.1'
  s.add_dependency 'sinatra' # for the sidekiq web UI
  s.add_dependency 'yajl-ruby', '~> 1.1.0'
  s.add_dependency 'omniauth-heroku', '~> 0.1.2.pre'
  s.add_dependency 'rails_12factor', '~> 0.0.2'
  s.add_dependency 'ladda-sprockets', '~> 0.7.2'

  s.add_development_dependency 'pg', '~> 0.16.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'sdoc'
  s.add_development_dependency 'rspec-rails', '~> 2.14.0'
  s.add_development_dependency 'factory_girl_rails', '~> 4.2.1'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'foreman'
end
