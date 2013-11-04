# Deathstare

Deathstare is a set of tools for load-testing JSON REST APIs.
It provides a promise-alike JSON REST API client, a Rails engine-based
web dashboard, auto-scaling test workers on Heroku, and streaming
results to/from Librato.

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

## TODO

* Extract/generalize ClientDevice and the warmup/setup process.

## Doc TODO

* Explain process for setting up hosting app, perhaps with a generator script or Rails template?
* Discuss Librato integration and setup requirements
* Discuss configuring client ID for Heroku OAuth
* Document writing of test suites, and debugging them
* Explain that Gemfile of hosting app needs s.add_dependency 'omniauth-heroku', git: 'git@github.com:cloudcity/omniauth-heroku.git', branch: 'report_uid_and_extra_params', ref: 'c1250900744ba96993f49926f2c4021d735aef8e' (because gemspec cannot specify a git resource) until Heroku merges my pull request

