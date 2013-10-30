# Deathstare -- Cloud-based Load-Testing

Deathstare is a Rails engine that you can include into your project. It
provides controllers and views and Sidekiq background jobs to farm out
your load test scripts into the Heroku cloud.

## Dependencies

* Heroku APP ID
* Librato Account to gather stats

## Running the specs

Run the specs using rspec:

    rake spec

You can view the coverage report as well.

    open coverage/index.html

## Configuration

Mount the engine:

    MyRails::Application.routes.draw do
      mount Deathstare::Engine => '/'
    end

And configure it, possibly in an initializer:

    Deathstare.configure do
      config.heroku_app_id       = 'Your Heroku App ID'
      config.heroku_oauth_id     = 'Your Heroku OAuth ID'
      config.heroku_oauth_secret = 'Your Heroku OAuth secret'
      config.librato_email       = 'Your Librato email address'
      config.librato_api_token   = 'Your Librato API token'
      config.target_urls << 'https://target.co/api'
      config.target_urls << 'http://stage.target.co/api'
    end

## Deathstare Suite

Deathstare will exercise your app by running suites of load tests against your target
server--the Deathstare suites. Because the suite files are specific to your app,
they live in a different place--a separate gem that you'll need to create and include
into Deathstare's `Gemfile`.

To create this custom Gem with your test suite, run from the Deathstare project root:

   rails plugin new ../my_load_tests -B -S -d postgresql -J --dummy-path=spec/dummy --mountable

Inside of `/my_load_tests`, create a `/suite` folder to contain your suite files.

## Fake and Specs

As the load tests are, in essence, simulating client devices, you may need to fake the
client behavior. To this end, you may need to write code to simulate the client device.
This code is in `lib/deathstare/fake`.

It may be handy to use TDD to build the client simulator. You can do this in rspec just
like for any other app. The files are in `/spec` of your Gem.

### Running Specs

There is a "dummy app" inside the spec folder that acts as the app which hosts the gem. All standard Rails rake
tasks are available through this app but prefixed with the `app` namespace. So, in order to initialize the databases
specified in `/spec/dummy/config/database.yml`, run _from the top-level:_

    rake app:db:create:all
    rake app:db:migrate

Then run the specs as usual:

    rake spec

## TODO

* Extract/generalize ClientDevice and the warmup/setup process.

## Doc TODO

* Explain process for setting up hosting app, perhaps with a generator script or Rails template?
* Discuss Librato integration and setup requirements
* Discuss configuring client ID for Heroku OAuth
* Document writing of test suites, and debugging them
* Explain that Gemfile of hosting app needs s.add_dependency 'omniauth-heroku', git: 'git@github.com:cloudcity/omniauth-heroku.git', branch: 'report_uid_and_extra_params', ref: 'c1250900744ba96993f49926f2c4021d735aef8e' (because gemspec cannot specify a git resource) until Heroku merges my pull request

