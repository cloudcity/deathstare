namespace :deathstare do
  namespace :sessions do
    def end_point
      base_url = ENV['BASE_URL'] || 'http://localhost:3000'
      Deathstare::EndPoint.find_by_base_url base_url or raise "unrecognized end point: #{base_url}"
    end

    desc "reset cached devices and sessions"
    task :reset => :environment do |t|
      print "Clearing device and session cache..."
      end_point.clear_upstream_sessions
      puts "done."
    end
  end
end
