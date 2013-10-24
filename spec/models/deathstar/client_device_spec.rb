require 'spec_helper'

module Deathstar
  describe ClientDevice do

    context "registration and log in" do
      it "already logged in" do
        @token = nil
        device = ClientDevice.generate FactoryGirl.create(:end_point)
        device.save!
        device.update(session_token: SecureRandom.uuid) # simulate existing session

        device.register_and_login(double('Client')).then do |r|
          @token = r[:response][:session_token]
        end
        expect(@token).to eq(device.session_token)
      end

      it "with complete success" do
        device = ClientDevice.generate FactoryGirl.create(:end_point)
        device.save!

        client = double('Client')
        @session_token = SecureRandom.uuid

        expect(client).to receive(:http).
                            with(:post, '/api/client_devices', device.to_device_h).
                            and_return(RequestPromise::Success.new(response: {}))

        expect(client).to receive(:http).
                            with(:post, '/api/users', device.to_device_h.merge(
          username: device.user_name,
          email: device.user_email,
          password: device.user_password)).
                            and_return(RequestPromise::Success.new(response: {user_id: 123}))

        expect(client).to receive(:http).
                            with(:post, '/api/login', device.to_device_h.merge(
          email_username: device.user_email,
          password: device.user_password)).
                            and_return(RequestPromise::Success.new(response: {session_token: @session_token}))

        device.register_and_login(client).then { |r|
          # final promise gets login result
          expect(r[:response][:session_token]).to eq @session_token
        }
        # device gets the session token
        expect(device.session_token).to eq @session_token
      end

      it "with session creation failure" do
        device = ClientDevice.generate FactoryGirl.create(:end_point)
        device.save!
        client = double('Client')

        expect(client).to receive(:http).
                            with(:post, '/api/client_devices', device.to_device_h).
                            and_return(RequestPromise::Success.new(response: {}))

        expect(client).to receive(:http).
                            with(:post, '/api/users', device.to_device_h.merge(
          username: device.user_name,
          email: device.user_email,
          password: device.user_password)).
                            and_return(RequestPromise::Success.new(response: {user_id: 123}))

        expect(client).to receive(:http).
                            with(:post, '/api/login', device.to_device_h.merge(
          email_username: device.user_email,
          password: device.user_password)).
                            and_return(RequestPromise::Failure.new('failed login'))

        device.register_and_login(client).then \
        ->(r) { fail "success? #{r}" }, ->(reason) { expect(reason).to eq 'failed login' }
        expect(device.session_token).to be_nil
      end

      it "with user creation failure" do
        device = ClientDevice.generate FactoryGirl.create(:end_point)
        device.save!
        client = double('Client')

        expect(client).to receive(:http).
                            with(:post, '/api/client_devices', device.to_device_h).
                            and_return(RequestPromise::Success.new(response: {}))

        expect(client).to receive(:http).
                            with(:post, '/api/users', device.to_device_h.merge(
          username: device.user_name,
          email: device.user_email,
          password: device.user_password)).
                            and_return(RequestPromise::Failure.new('failed to create user'))

        device.register_and_login(client).then \
        ->(r) { fail "success? #{r}" }, ->(reason) { expect(reason).to eq 'failed to create user' }
        expect(device.session_token).to be_nil
      end

      it "with device creation failure" do
        device = ClientDevice.generate FactoryGirl.create(:end_point)
        device.save!
        client = double('Client')

        expect(client).to receive(:http).
                            with(:post, '/api/client_devices', device.to_device_h).
                            and_return(RequestPromise::Failure.new('failed to register device'))

        device.register_and_login(client).then \
        ->(r) { fail "success? #{r}" }, ->(reason) { expect(reason).to eq 'failed to register device' }
        expect(device.session_token).to be_nil
      end
    end
  end
end
