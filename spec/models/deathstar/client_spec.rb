require 'spec_helper'

module Deathstar
  describe Client do
    it 'processes a successful JSON response' do
      promise = Client.new('http://test.host').http :get, '/foods/burrito'
      promise.then { |response| @response = response }

      promise.handle_response double('Typhoeus::Response', success?: true,
                                     body: Yajl::Encoder.encode({foo: 'bar'}),
                                     response_code: 200, status_message: 'OK', total_time: 1,
                                     request: double('Typhoeus::Request', options: {method: 'get'}, url: ''))

      expect(@response).to eq(
                             _response_meta: {request_method: "GET", request_url: "", status_code: 200, status_message: "OK", total_time: 1},
                             foo: "bar"
                           )
    end

    it 'processes a failed response' do
      promise = Client.new('http://test.host').http :get, '/foods/burrito'
      promise.then ->(r) {}, ->(reason) { @response = reason }
      promise.handle_response double('Typhoeus::Response', success?: false, status_message: '500 LOL', body:'stuff',
                                     request: double('Typhoeus::Request', options: {method: 'get'}, url: ''))

      expect(@response).to eq "Request failed: 500 LOL\nstuff"
    end
  end
end
