# Preload the performance test suite. This is needed to list available suites.
Dir[Rails.root.join('suite/**/*.rb')].sort.each { |path| require path }

