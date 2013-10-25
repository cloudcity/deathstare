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

    bundle exec rspec

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
      config.librato_email       = 'Your Librato email address'
      config.librato_api_token   = 'Your Librato API token'
      config.target_urls << 'https://target.co/api'
      config.target_urls << 'http://stage.target.co/api'
    end

## Deathstar Suite

Deathstar will exercise your app by running suites of load tests against your target
server--the Deathstar suites. Because the suite files are specific to your app,
they live in a different place--a separate gem that you'll need to create and include
into Deathstar's `Gemfile`.

To create this custom Gem with your test suite, run from the Deathstar project root:

   rails plugin new ../my_load_tests -B -S -d postgresql -J --dummy-path=spec/dummy --mountable

Inside of `/my_load_tests`, create a `/suite` folder to contain your suite files.

## Fake and Specs

As the load tests are, in essence, simulating client devices, you may need to fake the
client behavior. To this end, you may need to write code to simulate the client device.
This code is in `lib/deathstar/fake`.

It may be handy to use TDD to build the client simulator. You can do this in rspec just
like for any other app. The files are in `/spec` of your Gem.

## TODO

* Extract/generalize ClientDevice and the warmup/setup process.

## Doc TODO

* Explain process for setting up hosting app, perhaps with a generator script or Rails template?
* Discuss Librato integration and setup requirements
* Discuss configuring client ID for Heroku OAuth
* Document writing of test suites, and debugging them

