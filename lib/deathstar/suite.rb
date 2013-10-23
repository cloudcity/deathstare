require 'deathstar/device'
require 'deathstar/suite_helper'

require 'sidekiq/worker'
require 'active_support/core_ext/hash/indifferent_access'
require 'librato/metrics/typheous_client'
require 'librato/metrics/persistence/typheous_direct'

module Deathstar
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

    # Perform a test suite or individual test. This is the Sidekiq endpoint.
    #
    # @option opts :test_session_id [Integer] ActiveRecord ID of the user-specified test run
    # @option opts :name [String] test name to run, optional
    # @option opts :device_offset [Integer] Device offset, used for parallel test runs
    # @option opts :client [Client] Optional client handle
    # @return [void]
    def perform opts
      opts = opts.with_indifferent_access # opts is JSON-decoded and has string keys
      @session = TestSession.find(opts[:test_session_id])
      @device_offset = opts[:device_offset] || 0
                                          # Set concurrency in Typheous to devices per instance + 1 for reporting to Librato
      @client = opts[:client] || Client.new(@session.base_url, max_concurrency: @session.devices+1 > 200 ? 200 : @session.devices+1)
      @librato_queues = {}

      if opts[:name]
        run_test opts[:name], @session.run_time
      else
        test_names.each do |test_name|
          run_test test_name, @session.run_time
        end
      end
    end

    # Run the named test.
    # @param test_name [String]
    # @param run_time [Integer]
    # @return [void]
    def run_test test_name, run_time=0
      if @session.client_devices.count < @session.devices
        fail_setup 'Not enough cached devices! Call #initialize_devices on the session first.'
      end

      end_time = DateTime.now.to_i + run_time
      @session.client_devices.offset(@device_offset).limit(@session.devices).each do |cd|
        run_test_iteration test_name, cd, end_time
      end

      begin
        @client.run
      rescue StandardError => e
        @session.log "uncaught exception", ([e.message] + e.backtrace).join("\n")
        raise e
      end

      # autosubmit is set, this is just to get the stragglers
      @librato_queues.values.each { |queue| queue.submit }
      @librato_queues = {}
    end

    # List all test names in the suite.
    # @return [Array<String>]
    def test_names
      methods.map { |m| m.to_s =~ /test: (.+)/; $1 }.compact.sort
    end

    private

    # Log a test result message and raise a standard exception.
    def fail_setup message
      @session.log 'setup', message
      raise message
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
        # 2038 bug!
        if end_time && DateTime.now.to_i < end_time
          run_test_iteration name, client_device, end_time
        else
          @session.log 'completion', "Test `#{name}' completed!"
        end
      },
      -> (reason) {
        @session.log 'completion', "Test `#{name}' failed!\n#{reason}"
      }
    end

    class << self
      def inherited subclass
        Deathstar::Suite.suites << subclass
      end

      # Declares a test case. Provide a name and implementation.
      def test desc, &block
        define_method("test: #{desc}", block)
      end
    end
  end
end
