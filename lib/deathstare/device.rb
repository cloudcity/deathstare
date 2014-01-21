require 'deathstare/request_promise'
require 'deathstare/client'

# A device simulates a single DSAPI consumer device. Wraps a {Client} connection.
# This is the primary API for implementing load test cases, along with {SuiteHelper}.
# It's also responsible for logging test responses, for debugging and metrics.
module Deathstare
  class Device
    extend Forwardable

    # @!attribute [r] info
    #   @return [OpenStruct] session information
    def_instance_delegators :@upstream_session, :info

    # @return [TestSession] Associated test session.
    attr_reader :test_session

    def session_token
      info.session_token
    end

    # Create a new device connection. All options are required.
    #
    # @param client [Client] client API handle
    # @option opts upstream_session [UpstreamSessions] upstream session instance
    # @option opts test_session [TestSession] test session instance
    # @option opts suite_name [String] name of the suite
    # @option opts test_name [String] name of the test
    # @option opts librato_queue [Librato::Metrics::Queue] queue for the current test
    def initialize client, opts
      @client = client
      @upstream_session = opts[:upstream_session]
      @test_session = opts[:test_session]
      @suite_name = opts[:suite_name]
      @test_name = opts[:test_name]
      @librato_queue = opts[:librato_queue]
    end

    # @!method get(path, params={})
    #   @return [RequestPromise]
    # @!method put(path, params={})
    #   @return [RequestPromise]
    # @!method post(path, params={})
    #   @return [RequestPromise]
    # @!method patch(path, params={})
    #   @return [RequestPromise]
    # @!method delete(path, params={})
    #   @return [RequestPromise]
    %w[ get post put patch delete ].each do |verb|
      define_method verb do |path, params={}|
        raise "specified path is not absolute: #{path}" unless path =~ /^\//
        # XXX upstream session should specify canonical session info
        @client.http(verb, path, params.merge(@upstream_session.session_params)).
          then ->(response) { log_response response }, ->(reason) { log_error reason }
      end
    end

    protected

    # Log a failed request.
    def log_error message
      $stderr.puts message if Rails.env.development?
      @test_session.test_results << TestResult.new(suite_name: @suite_name, test_name: @test_name, messages: message, error:true)
      message
    end

    # Record results and metrics given a response hash from DSClient.
    def log_response response
      response[:_response_meta].tap do |meta|
        @librato_queue.add(response_code: meta[:status_code].to_i,
                           response_time: meta[:total_time] * 1000.0) # milliseconds
      end
      if @test_session.verbose
        @test_session.test_results << TestResult.from_response(@suite_name, @test_name, response)
      end
      response
    end
  end
end

