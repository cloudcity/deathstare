module Deathstar # Represents a single DSAPI end point. Multiple {TestSession} instances with the same base URL
                 # will share an end point. End points are used to manage cached {ClientDevice} records.
  class EndPoint < ActiveRecord::Base
    TARGET_SERVERS = ['http://taco.town']
    TARGET_SERVERS.unshift 'http://localhost:3000' if Rails.env.development?
    TARGET_SERVERS.unshift 'http://test.host' if Rails.env.test?
    TARGET_SERVERS.unshift ENV['BASE_URL'] if ENV['BASE_URL'].present?
    private_constant :TARGET_SERVERS # We don't want to expose the defaults in the docs

    # Get a list of end point names, this is used in the "End point" drop down in the web dashboard.
    # @return [Array<String>] list of end points
    def self.target_servers
      TARGET_SERVERS
    end

    validates :base_url, inclusion: TARGET_SERVERS
    before_validation :set_defaults

    has_many :test_sessions, :dependent => :delete_all
    has_many :client_devices, :dependent => :delete_all

    # Generate random client devices until the cache has the requested amount.
    # If there are already enough devices in the cache this will be a no-op.
    #
    # @param device_count [Integer] number of devices to create
    # @return [void]
    def generate_devices device_count
      return if client_devices.count >= device_count
      print "Generating #{device_count} devices..." if Rails.env.development?
      (device_count - client_devices.count).times { generate_client_device }
      puts 'done.' if Rails.env.development?
    end

    # Ensure every generate client device has a session token, register and login
    # the ones that don't. This method blocks until it's completed.
    #
    # @param client [Client]
    # @param success [Proc] success callback
    # @param failure [Proc] failure callback
    # @return [void]
    def register_and_login_devices client, success=nil, failure=nil, &callback
      success ||= callback
      client_devices.not_logged_in.each do |device|
        device.register_and_login(client).then success, failure
      end
      client.run
    end

    # Clear the client device cache. This is needed whenever the upstream end point is reset.
    # @return [void]
    def clear_cached_devices
      client_devices.delete_all
    end

    private

    def generate_client_device
      device = nil
      until device && device.save # make sure we get a valid device
        device = ClientDevice.generate(self)
      end
      device
    end

    def set_defaults
      self.base_url = TARGET_SERVERS.first if self.base_url.blank?
    end
  end
end
