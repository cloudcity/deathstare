# Deathstar -- Cloud-based Load-Testing

Deathstar is a Rails engine that you can include into your project. It
provides controllers and views and Sidekiq background jobs to farm out
your load test scripts into the Heroku cloud to send deathrays onto
your servers. Will the Empire prevail? Will the Force lead the rebellion
to victory? `gem install` and find out!

## Dependencies

* Heroku APP ID
* Librato Account to gather stats

## Running the specs

Run the specs using rspec:

    rspec

You can view the coverage report as well.

    open coverage/index.html

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
      config.target_urls << 'http://my.target.co/api'
    end

## TODO

* Get all the specs passing!
* Extract/generalize Device and the warmup/setup process.
* Explain process for setting up hosting app, perhaps with a generator script or Rails template?
* Document writing of test suites, and debugging them
* Document how/where to configure Heroku client app ID, OAuth keys, Librato credentials
