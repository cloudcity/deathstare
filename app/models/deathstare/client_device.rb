module Deathstare
  require 'faker'
  require 'securerandom'

  require 'deathstare/device'

  # Represents a cached device/user/session belonging to an upstream end point. Provides
  # tools to generate random devices and register them.
  # XXX APP-SPECIFIC XXX
  class ClientDevice < ActiveRecord::Base
    belongs_to :end_point
    validates_presence_of :client_device_id, :user_name, :user_email, :end_point_id
    validates_uniqueness_of :client_device_id, :user_name, :user_email, scope: :end_point_id

    # WARNING these are not indexed queries unless chained through EndPoint,
    # e.g.: `EndPoint.first.client_devices.created`
    scope :created, -> { where('deathstare_client_devices.client_device_created_at is not null') }
    scope :registered, -> { where('deathstare_client_devices.user_created_at is not null') }
    scope :logged_in, -> { where('deathstare_client_devices.session_created_at is not null') }
    scope :not_logged_in, -> { where('deathstare_client_devices.session_created_at is null') }

    # Generate a random ClientDevice given an end point. Does not attempt to save.
    #
    # @param end_point [EndPoint]
    # @return [ClientDevice]
    def self.generate end_point
      new(
        end_point_id: end_point.id,
        client_device_id: SecureRandom.uuid,
        user_name: SecureRandom.hex(20),
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

      register_device(client).then do
        create_user(client, user_name, user_email, user_password).then do
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
      if client_device_created_at.nil?
        client.http(:post, '/api/client_devices', to_device_h).
          then { |r| update(client_device_created_at: DateTime.now); r }
      else
        RequestPromise::Success.new(nil)
      end
    end

    # Create a user upstream. This sets the user_id upon completion.
    # @return [RequestPromise] The resulting promise
    def create_user client, name, email, password
      if user_created_at.nil?
        client.http(:post, '/api/users', to_device_h.merge(username: name, email: email, password: password)).
          then { |r| update(user_created_at: DateTime.now, user_id: r[:response][:id]); r }
      else
        RequestPromise::Success.new(nil)
      end
    end

    # You need to log in to perform API calls. After this is complete you have a session_token.
    # @return [RequestPromise] The resulting promise
    def login client, email, password
      if session_token.nil?
        client.http(:post, '/api/login', to_device_h.merge(email_username: email, password: password)).
          then { |r| update(session_created_at: DateTime.now, session_token: r[:response][:session_token]); r }
      else
        RequestPromise::Success.new(response: {session_token: session_token})
      end
    end

  end
end
