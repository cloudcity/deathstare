require 'deathstare/device'
require 'deathstare/suite_helper'

require 'sidekiq/worker'
require 'active_support/core_ext/hash/indifferent_access'

require 'librato/metrics'
require 'librato/metrics/typheous_client'
require 'librato/metrics/persistence/typheous_direct'

module Deathstare
  # Subclass TestSuite to create a worker that performs your tests (specified with
  # a call to `test`) as a suite. When enqueuing that worker, pass in the ID for the test
  # session with the configuration details and an optional name.
  #
  #     MySuite.perform_async(test_session_id:1, name:'my favorite test')
  #
  class Suite
    include ::Sidekiq::Worker
    include SuiteHelper

    sidekiq_options :retry => false, :backtrace => true

    # Contains an array of Suite subclasses, use this to iterate over every suite.
    # @return [Array<Class>]
    def self.suites
      @suites ||= []
    end

    # Initialize a test session. Accepts the same options as `perform`
    def initialize opts=nil
      return unless opts
      @session = TestSession.find(opts[:test_session_id])
      @test_names = opts[:test_names] || self.class.test_names
      @device_offset = opts[:device_offset] || 0
                                          # Set concurrency in Typheous to devices per instance + 1 for reporting to Librato
      @client = opts[:client] || Client.new(@session.base_url, max_concurrency: @session.devices+1 > 200 ? 200 : @session.devices+1)
      @librato_queues = {}
    end

    # Perform a test suite or individual test. This is the Sidekiq endpoint.
    #
    # @option opts :test_session_id [Integer] ActiveRecord ID of the user-specified test run
    # @option opts :test_names [String] multiple test names to run, optional
    # @option opts :name [String] single test name to run, overrides `test_names` XXX
    # @option opts :device_offset [Integer] Device offset, used for parallel test runs
    # @option opts :client [Client] Optional client handle
    # @return [void]
    def perform opts
      opts = opts.with_indifferent_access # opts is JSON-decoded and has string keys
      initialize opts
      if opts[:name]
        run_tests [opts[:name]], @session.run_time
      else
        run_tests @test_names, @session.run_time
      end
    end

    # Run the named tests.
    # @param test_names [Array<String>]
    # @param run_time [Integer]
    # @return [void]
    def run_tests test_names, run_time=0
      if @session.client_devices.count < @session.devices
        fail_setup 'Not enough cached devices! Call #initialize_devices on the session first.'
      end

      end_time = DateTime.now.to_i + run_time
      test_count = test_names.count
      @session.client_devices.offset(@device_offset).limit(@session.devices).each_with_index do |cd, i|
        run_test_iteration test_names[i%test_count], cd, end_time
      end

      begin
        @client.run
      rescue StandardError => e
        @session.log_error "uncaught exception", ([e.message] + e.backtrace).join("\n")
        end_suite
        raise e
      end

      # autosubmit is set, this is just to get the stragglers
      @librato_queues.values.each { |queue| queue.submit }
      @librato_queues = {}

      end_suite
    end

    # List all test names in the suite.
    # @return [Array<String>]
    def self.test_names
      instance_methods.map { |m| m.to_s =~ /test: (.+)/; $1 }.compact.sort
    end

    private

    # If we're the last running worker, mark the end of the session
    def end_suite
      if Sidekiq::Workers.new.size <= 1 # number of *active* workers
        @session.log "completion", "The session has ended."
        @session.end_session
      end
    end

    # Log a test result message and raise a standard exception.
    def fail_setup message
      @session.log_error 'setup', message
      end_suite
    end

    # Get a new librato queue for the named test.
    def librato_queue name
      @librato_queues[name] ||=
        Librato::Metrics::Queue.new(source: "test_session_#{@session.id}",
                                    prefix: name.gsub(/\W+/, '_'),
                                    autosubmit_count: 100,
                                    client: Librato::Metrics::TypheousClient.new(@client.hydra))
    end

    # Run a single test iteration.
    def run_test_iteration name, client_device, end_time=nil
      device = Device.new(@client,
                          client_device: client_device,
                          test_session: @session,
                          suite_name: self.class.name,
                          test_name: name,
                          librato_queue: librato_queue(name))
      send("test: #{name}", device).then \
      ->(result) {
        if @session.reload.cancelled?
          @session.log 'completion', "#{self.class.name}: `#{name}' was cancelled!"
          result
        elsif end_time && DateTime.now.to_i < end_time
          run_test_iteration name, client_device, end_time
        else
          @session.log 'completion', "#{self.class.name}: `#{name}' completed!"
          result
        end
      },
      -> (reason) {
        @session.log_error 'completion', "#{self.class.name}: `#{name}' failed, suite has ended early!"
        reason
      }
    end

    class << self
      def inherited subclass
        Deathstare::Suite.suites << subclass
      end

      # Declares a test case. Provide a name and implementation.
      def test desc, &block
        define_method("test: #{desc}", block || Proc.new {})
      end
    end
  end
end
