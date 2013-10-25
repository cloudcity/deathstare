# Use Pry instead of IRB for the rails console
Rails.application.config.console do
  require 'pry'
  puts %{Try, e.g.:
> session = Deathstar::TestSession.create base_url:'http://localhost:3000',  devices: 10
> session.initialize_devices
> MySuite.new.perform test_session_id:session.id, name:'my favorite test'}
  Rails.application.config.console = Pry
end
