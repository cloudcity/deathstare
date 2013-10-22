module Deathstar
  require 'faker'
  require 'securerandom'

  require 'deathstar/device'

# Represents a cached device/user/session belonging to an upstream end point. Provides
# tools to generate random devices and register them with DSAPI.
  class ClientDevice < ActiveRecord::Base
    belongs_to :end_point
    validates_presence_of :client_device_id, :user_name, :user_email, :end_point_id
    validates_uniqueness_of :client_device_id, :user_name, :user_email, scope: :end_point_id

    # WARNING these are not indexed queries unless chained through EndPoint,
    # e.g.: `EndPoint.first.client_devices.created`
    scope :created, -> { where('client_devices.client_device_created_at is not null') }
    scope :registered, -> { where('client_devices.user_created_at is not null') }
    scope :logged_in, -> { where('client_devices.session_created_at is not null') }
    scope :not_logged_in, -> { where('client_devices.session_created_at is null') }

    # Generate a random ClientDevice given an end point. Does not attempt to save.
    #
    # @param end_point [EndPoint]
    # @return [ClientDevice]
    def self.generate end_point
      new(
        end_point_id: end_point.id,
        client_device_id: SecureRandom.uuid,
        user_name: Faker::Name.name.parameterize,
        user_email: Faker::Internet.email,
        user_password: SecureRandom.urlsafe_base64
      )
    end

    # Register and log in, given a client handle. Can only be called on saved instances.
    #
    # @param client [Client]
    # @return [RequestPromise] fires on completion of login or failure
    def register_and_login client
      raise 'save the client device before registering' unless persisted?
      if session_token # already logged in
        return RequestPromise::Success.new(response: {session_token: session_token})
      end

      register_device(client).then do |result|
        create_user(client, user_name, user_email, user_password).then do |result|
          login(client, user_email, user_password)
        end
      end
    end

    # @return [Hash] Client device information.
    def to_device_h
      {client_device_id: client_device_id}
    end

    private

    # Register a device upstream.
    # @return [RequestPromise] The resulting promise
    def register_device client
      client.http(:post, '/api/client_devices', to_device_h).
        then { |r| update(client_device_created_at: DateTime.now); r }
    end

    # Create a user upstream. This sets the user_id upon completion.
    # @return [RequestPromise] The resulting promise
    def create_user client, name, email, password
      client.http(:post, '/api/users', to_device_h.merge(username: name, email: email, password: password)).
        then { |r| update(user_created_at: DateTime.now, user_id: r[:response][:id]); r }
    end

    # You need to log in to perform API calls. After this is complete you have a session_token.
    # @return [RequestPromise] The resulting promise
    def login client, email, password
      client.http(:post, '/api/login', to_device_h.merge(email_username: email, password: password)).
        then { |r| update(session_created_at: DateTime.now, session_token: r[:response][:session_token]); r }
    end

  end
end
