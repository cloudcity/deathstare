# Deathstar -- Cloud-based Load-Testing

Deathstar is a Rails engine that you can include into your project. It
provides controllers and views and Sidekiq background jobs to farm out
your load test scripts into the Heroku cloud to send deathrays onto
your servers. Will the Empire prevail? Will the Force lead the rebellion
to victory? `gem install` and find out!

## Dependencies

* Heroku APP ID
* Librato Account to gather stats

## Configuration

Mount the engine:

    MyRails::Application.routes.draw do
      mount Deathstar::Engine => '/'
    end

And configure it, possibly in an initializer:

    Deathstar.configure do
      config.heroku_app_id       = 'Your Heroku App ID'
      config.heroku_oauth_id     = 'Your Heroku OAuth ID'
      config.heroku_oauth_secret = 'Your Heroku OAuth secret'

      # XXX TODO
      config.target_servers << 'http://my.test.host'
    end

## TODO

* XXX The specs do not pass! XXX
* Generalize HTTP client and suite setup facilities.
* Explain process for setting up hosting app, perhaps with a generator script or Rails template?
* Document writing of test suites, and debugging them
* Document how/where to configure Heroku client app ID, OAuth keys, Librato credentials
