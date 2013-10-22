require 'spec_helper'

module Deathstar
  describe Suite do
    it 'lists tests in alphabetical order' do
      test_names = [
        'take a break',
        'do nothing',
        'do nothing again',
        'enjoy a life of leisure'
      ]
      suite = Class.new(Suite)
      test_names.each { |test_name| suite.test(test_name) {} }

      expect(suite.new.test_names).to eq test_names.sort
    end

    context "with a session" do
      before do
        # fake up a session and a single logged-in client_device
        @session_token = SecureRandom.uuid
        @session = FactoryGirl.create(:test_session)
        @session.end_point.client_devices << ClientDevice.generate(@session.end_point).
          tap { |cd| cd.session_token = @session_token }
        @suite = Class.new(Suite)
        @suite.test 'request a snack' do |device|
          device.stub(:log_response) # stub out logging
          device.get("/meals/snack")
        end
      end

      it 'logs successful completion' do
        client = double('Client', hydra: nil)
        expect(client).to receive(:run)
        expect(client).to receive(:http).with('get', '/meals/snack', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))

        expect(TestSession).to receive(:find).and_return @session
        expect(@session).to receive(:log).with('completion', "Test `request a snack' completed!")
        @suite.new.perform(test_session_id: @session.id, client: client, name: 'request a snack')
      end

      it 'logs failure' do
        client = double('Client', hydra: nil)
        client.stub(:run)
        client.stub(http: RequestPromise::Failure.new('lol jk'))

        expect(TestSession).to receive(:find).and_return @session
        expect(@session).to receive(:log).with('completion', "Test `request a snack' failed!\nlol jk")
        @suite.new.perform(test_session_id: @session.id, client: client, name: 'request a snack')
      end

      it 'runs a test for wallclock time' do
        client = double('Client', hydra: nil)
        expect(client).to receive(:run)
        expect(client).to receive(:http).at_least(3).times.with('get', '/meals/snack', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))

        @session.update(run_time: 1)
        timestamp = DateTime.now.to_i
        @suite.new.perform(test_session_id: @session.id, client: client, name: 'request a snack')
        expect(DateTime.now.to_i).to be >= timestamp + 1
      end

      it 'chains requests by repeat count' do
        @suite.test 'repeat 3 times' do |device|
          device.stub(:log_response) # stub out logging
          request_times(3) { device.get("/meals/snack") }
        end

        client = double('Client', hydra: nil)
        expect(client).to receive(:run)
        expect(client).to receive(:http).exactly(3).times.with('get', '/meals/snack', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))

        @suite.new.perform(test_session_id: @session.id, client: client, name: 'repeat 3 times')
      end

      it 'chains requests over a sequence' do
        @suite.test 'repeat some foods' do |device|
          device.stub(:log_response) # stub out logging
          request_each(%w[ breakfast lunch dinner ]) { |m| device.get("/meals/#{m}") }
        end

        client = double('Client', hydra: nil)
        expect(client).to receive(:run)
        expect(client).to receive(:http).with('get', '/meals/breakfast', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))
        expect(client).to receive(:http).with('get', '/meals/lunch', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))
        expect(client).to receive(:http).with('get', '/meals/dinner', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))

        @suite.new.perform(test_session_id: @session.id, client: client, name: 'repeat some foods')
      end
    end
  end
end
