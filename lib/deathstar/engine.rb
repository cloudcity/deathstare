module Deathstar
  class Engine < ::Rails::Engine
    require 'haml'
    require 'ladda-sprockets'

    isolate_namespace Deathstar

    config.generators do |g|
      g.fixture_replacement :factory_girl
    end

  end
end
