require 'spec_helper'

module Deathstare
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

      expect(suite.test_names).to eq test_names.sort
    end

    it 'runs tests interleaved' do
      session_token = SecureRandom.uuid
      session = FactoryGirl.create(:test_session, devices:9)
      9.times do
        session.end_point.upstream_sessions << SpecSession.with_token(session_token)
      end
      suite = Class.new(Suite)
      suite.test('get a snack') {|d| }
      suite.test('have coffee') {|d| }
      suite.test('skip dinner') {|d| }

      client = double('Client', hydra: nil, run:nil)
      my_suite = suite.new(test_session_id: session.id, client: client)
      expect_args = [kind_of(SpecSession), kind_of(Integer)]

      3.times do
        expect(my_suite).to receive(:run_test_iteration).with('get a snack', *expect_args).ordered
        expect(my_suite).to receive(:run_test_iteration).with('have coffee', *expect_args).ordered
        expect(my_suite).to receive(:run_test_iteration).with('skip dinner', *expect_args).ordered
      end
      my_suite.run_tests ['get a snack', 'have coffee', 'skip dinner'], 0
    end

    context "with a session" do
      before do
        # fake up a session and a single logged-in client_device
        @session_token = SecureRandom.uuid
        @session = FactoryGirl.create(:test_session)
        @session.end_point.upstream_sessions << SpecSession.with_token(@session_token)
        @suite = Class.new(Suite)
        @suite.test 'request a snack' do |device|
          device.stub(:log_response) # stub out logging
          device.get("/meals/snack")
        end
        TestSession.stub(find:@session)
      end

      it 'cancels a suite' do
        client = double('Client', hydra: nil)
        expect(client).to receive(:run)
        expect(client).to receive(:http).with('get', '/meals/snack', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))
        expect(@session).to receive(:log).with('completion', ": `request a snack' was cancelled!")
        expect(@session).to receive(:log).with('completion', "The session has ended.")
        @session.cancel_session
        @suite.new.perform(test_session_id: @session.id, client: client, name: 'request a snack')
      end

      it 'logs successful completion' do
        client = double('Client', hydra: nil)
        expect(client).to receive(:run)
        expect(client).to receive(:http).with('get', '/meals/snack', session_token: @session_token).
                            and_return(RequestPromise::Success.new({}))

        expect(@session).to receive(:log).with('completion', ": `request a snack' completed!")
        expect(@session).to receive(:log).with('completion', "The session has ended.")
        @suite.new.perform(test_session_id: @session.id, client: client, name: 'request a snack')
      end

      it 'logs failure' do
        client = double('Client', hydra: nil)
        client.stub(:run)
        client.stub(http: RequestPromise::Failure.new('lol jk'))

        expect(@session).to receive(:log_error).with('completion', ": `request a snack' failed, suite has ended early!")
        expect(@session).to receive(:log).with('completion', "The session has ended.")
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
