# Need to require all our gems. Since they're not declared in the Gemfile they won't be auto-required.
require 'sass-rails'
require 'uglifier'
require 'coffee-rails'
require 'jquery-rails'
require 'bootstrap-sass-rails'
require 'will_paginate'
require 'haml'
require 'yard'
require 'faraday'
require 'typhoeus'
require 'librato/metrics'
require 'faker'
require 'sidekiq'
require 'sinatra'
require 'yajl'
require 'omniauth-heroku'
require 'rails_12factor'
require 'ladda-sprockets'

module Deathstar
  class Engine < ::Rails::Engine

    isolate_namespace Deathstar

    config.generators do |g|
      g.fixture_replacement :factory_girl
    end

  end
end
