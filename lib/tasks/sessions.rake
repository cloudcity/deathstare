namespace :deathstar do
  namespace :sessions do
    def end_point
      base_url = ENV['BASE_URL'] || 'http://localhost:3000'
      EndPoint.find_by_base_url base_url or raise "unrecognized end point: #{base_url}"
    end

    desc "reset cached devices and sessions"
    task :reset => :environment do |t|
      print "Clearing device and session cache..."
      end_point.clear_cached_devices
      puts "done."
    end

    desc "list cached devices and sessions by endpoint"
    task :show => :environment do |t|
      end_point.client_devices.each do |dc|
        puts "#{dc.client_device_id} #{dc.session_token}"
      end
    end
  end
end
