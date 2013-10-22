# Deathstar -- Cloud-based Load-Testing

Deathstar is a Rails engine that you can include into your project. It
provides controllers and views and Sidekiq background jobs to farm out
your load test scripts into the Heroku cloud to send deathrays onto
your servers. Will the Empire prevail? Will the Force lead the rebellion
to victory? `gem install` and find out!

## Dependencies

* Heroku APP ID
* Librato Account -- for gather stats

## TODO

* Autoload for test suites broken
* Explain process for setting up hosting app, perhaps with a generator script or Rails template?
* Document writing of test suites, and debugging them
* Document how/where to configure Heroku client app ID, OAuth keys, Librato credentials
