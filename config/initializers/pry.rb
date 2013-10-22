# Use Pry instead of IRB for the rails console
Rails.application.config.console do
  require 'pry'
  puts %{Try, e.g.:
> session = TestSession.create base_url:'http://localhost:3000',  devices: 10
> MyLoadTest.new.perform test_session_id:session.id}
  Rails.application.config.console = Pry
end
