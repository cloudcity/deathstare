require 'deathstar/suite'

# This is also loaded in the initializer, but we need it before the Rails env loads
# so we can generate the suite tasks automatically.
Dir[Rails.root.join('suite/**/*.rb')].each { |path| require path }

namespace :suite do
  # These make it easier to catch mis-spelled names.
  BASE_URL = 'BASE_URL'.freeze
  DEVICES = 'DEVICES'.freeze
  CONCURRENCY = 'CONCURRENCY'.freeze

  task :env => :environment do
    ENV[BASE_URL] ||= 'http://localhost:3000'
    ENV[DEVICES] ||= '10'
  end

  Deathstar::Suite.suites.each do |suite|
    name = suite.name.gsub(/Suite$/, '').underscore
    desc "start #{suite.name}"
    task name => :env do
      Deathstar::TestSession.create!(
        suite_names: [suite.name],
        base_url: ENV[BASE_URL],
        devices: ENV[DEVICES],
        comment: "rake suite:#{name}"
      ).enqueue
      puts "Started %s with %s devices on %s" % [suite, ENV[DEVICES], ENV[BASE_URL]]
    end
  end
end
