# Deathstare

![alt tag](https://raw.github.com/cloudcity/deathstare/master/Deathstare-robots.png)

Deathstare is a set of tools for load-testing JSON REST APIs.
It provides a JSON REST API client with a promise styled approach to 
dependent concurrent operations, a Rails engine-based web dashboard, 
auto-scaling test workers on Heroku, and streaming results to/from Librato.

[![Build Status](https://travis-ci.org/cloudcity/deathstare.png?branch=master)](https://travis-ci.org/cloudcity/deathstare)

## Rationale

The reason we created Deathstare is that when we went looking for
custom DDOS tools, we found that they all provided a way to hammer
on a web site with lots of GET requests. However, our intended target
was not a web site, but a web-based API.

To this end, we built a set of tools that allowed us to create detailed,
application-specific performance test suites that can be scaled up to a
very large number of parallel requests.

## Dependencies

* Heroku APP ID
* Librato Account to gather stats

## Getting started

All of the needed set up is done in your own project,
for now we recommend starting with a newly generated Rails app.

Add deathstare to your `Gemfile`:

    gem 'deathstare', git: 'https://github.com/cloudcity/deathstare.git'

    You will need to include the following lines in the Gemfile of your testing application since gemspec cannot
    specify a git resource until Heroku merges our pull request

        # required for app identification to work correctly
        gem 'omniauth-heroku', git: 'https://github.com/cloudcity/omniauth-heroku.git', branch: 'report_uid_and_extra_params', ref: 'c1250900744ba96993f49926f2c4021d735aef8e'

Mount the engine in `config/routes.rb`:

    MyApp::Application.routes.draw do
      mount Deathstare::Engine => '/'
    end

And configure it in an initializer, e.g. `config/initializers/deathstare.rb`:

    Deathstare.configure do
      config.heroku_app_id       = 'Your Heroku App ID'
      config.heroku_oauth_id     = 'Your Heroku OAuth ID'
      config.heroku_oauth_secret = 'Your Heroku OAuth secret'
      config.librato_email       = 'Your Librato email address'
      config.librato_api_token   = 'Your Librato API token'
      config.target_urls << 'https://target.co/api'
      config.target_urls << 'http://stage.target.co/api'
    end

Install deathstare and run the migrations:

    bundle install
    rake deathstare:install:migrations
    rake db:create
    rake db:migrate

It's now possible to start the dashboard:

    rails server

Create a `suite` directory and populate it with subclasses of {Deathstare::Suite}.
These are your test suites! You can run them with rake or in the web dashboard.
To see a list of suites runnable with rake:

    rake -T suite:

To view this documentation locally in your browser, with the dashboard running:

    rake deathstare:yard
    open http://localhost:3000/doc

To scale your tests up using parallel workers, you need to deploy your application to Heroku.
This is left as an exercise for the reader.

# Development

### Running Specs

First, put your database configuration in `spec/dummy/config/database.yml`.

Then run the specs as usual:

    rake spec

You can view the coverage report as well.

    open coverage/index.html

### Updating The Spec Database

In order to update the spec database when you add a migration, you'll need to add the migration
to the dummy app and migrate it.

To avoid errors migrating from the root directory, go into the dummy app and migrate there.
For more info see https://github.com/rails/rails/issues/10952

    rake app:deathstare:install:migrations
    cd spec/dummy
    rake db:migrate


### Deploying to Heroku

When you run a Deathstare test app locally, you can specify multiple concurrent devices.

When you deploy that same Deathstare test app on Heroku, you can specify up to 100 concurrent instances running as well.
Each of those instances will present load for the number of concurrent devices you specify on the dashboard.

To set that up, you will have to deploy your test app to Heroku, set up OAuth for the application, and set up
three Heroku environment variables:

* `HEROKU_APP_ID`
* `HEROKU_OAUTH_ID`
* `HEROKU_OAUTH_SECRET`

When you run your test app on Heroku, you will have the option to set a number of concurrent instances (up to 100) for
your test run. That comes with the corresponding cost of running those Heroku instances during the test run, but it is
relatively inexpensive for the amount of load testing you will be able to generate. Deathstare spins down the instances
when the test run completes.
