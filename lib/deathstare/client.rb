require 'typhoeus'

# activesupport/rails4 json is still in flux:
# https://github.com/intridea/multi_json/pull/138#issuecomment-24468223
# ... and yajl is a known quantity performance- and API-wise
require 'yajl'

# This is an asynchronous HTTP JSON API client based on Typhoeus::Hydra, uses {RequestPromise}
# to provide a promise-based API. Queue requests with {#http} and start the request chain
# with {#run}. Requests can be queued in a complete callback to continue the chain.
# 
# The client is responsible for queueing connections, converting the payload to/from JSON,
# and storing response meta-information in the response hash.
module Deathstare

  class Client
    MIME_TYPE = 'application/json'.freeze
    private_constant :MIME_TYPE

    attr_reader :hydra # used by Librato Typheous client

    # Create an DSAPI client handle with the ability to perform concurrent requests.
    #
    # @param base_url [String] Base URL for all requests
    # @option opts :max_concurrency [Integer] Maximum concurrent connections
    def initialize base_url, opts={}
      @base_url = base_url
      @hydra = Typhoeus::Hydra.new(opts)
    end

    # Perform a request to the specified path.
    #
    # This returns a promise that when completed will return a hash decoded from the JSON body.
    # Adds a top-level response key `_response_meta` that holds a hash with the following keys:
    #
    # * :request_method
    # * :request_url
    # * :status_code
    # * :status_message
    # * :total_time
    #
    # @return [RequestPromise] A promise for a JSON-decoded hash with symbolized keys
    def http verb, path, params={}

      to_header = params.delete(:to_header)
      case verb.to_s.downcase

        when 'get' # use URL-encoded params for GET requests only
          if to_header
            to_header['Accept'] = MIME_TYPE
            request_opts = {method: verb, headers: to_header, params: params}
          else
            request_opts = {method: verb, headers: {'Accept' => MIME_TYPE}, params: params}
          end
        else # for everything else encode as JSON in the body
          encoded_param = Yajl::Encoder.encode params
          if to_header
            to_header['Content-type'] = MIME_TYPE
            request_opts = {method: verb, headers: to_header, body: encoded_param }
          else
            request_opts = {method: verb, headers: { 'Content-type' => MIME_TYPE }, body: encoded_param }

          end
      end

      request = Typhoeus::Request.new @base_url+path, request_opts

      @hydra.queue request

      RequestPromise.new(request).then do |response|
        # we always expect JSON from successful responses
        response_meta(response).merge Yajl::Parser.parse(response.body, symbolize_keys: true)
      end
    end

    # Start the HTTP request chain.
    # @return [void]
    def run
      @hydra.run
    end

    private

    def response_meta response
      {_response_meta: {
        request_method: response.request.options[:method].upcase,
        request_url: response.request.url,
        status_code: response.response_code,
        status_message: response.status_message,
        total_time: response.total_time,
      }}
    end
  end
end

