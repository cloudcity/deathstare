require 'spec_helper'

module Deathstare

  module RequestPromiseHelper
    def stub_request
      double("TyphoeusRequest").tap do |request|
        expect(request).to receive(:on_complete)
      end
    end
  end
  RSpec.configure do |c|
    c.include RequestPromiseHelper
  end

  describe RequestPromise do
    context 'singular requests' do
      before do
        @request = stub_request
      end

      it 'calls the success callback via block' do
        @food = "burrito"
        promise = RequestPromise.new(@request).then { |r| @food = r[:food] }
        promise.send :resolve, {food: 'taco'} # simulate successful request
        expect(@food).to eq 'taco'
      end

      it 'calls the success callback via lambda' do
        @food = "burrito"
        promise = RequestPromise.new(@request).then ->(r) { @food = r[:food] }
        promise.send :resolve, {food: 'taco'} # simulate successful request
        expect(@food).to eq 'taco'
      end

      it 'calls the failure callback' do
        @food = "nachos"
        promise = RequestPromise.new(@request).then \
        ->(r) { @food = r[:food] },
        ->(r) { @food += " failed: #{r}" }
        promise.send :reject, 'no salsa :(' # simulate failed request
        expect(@food).to eq 'nachos failed: no salsa :('
      end
    end

    context 'dependent requests' do
      before do
        @initial_request = stub_request
        @second_request = stub_request
      end

      it 'passes nested promises up the chain' do
        @food = "burrito"
        initial_promise = RequestPromise.new(@initial_request).then do |r|
          @food = r[:food]
          # first then callback returns a promise...
          @second_promise = RequestPromise.new(@second_request)
        end
        # ...and subsequent callbacks are fired on the dependent promise
        initial_promise.then { |r| @food += " with #{r[:topping]||'nothing :('}" }

        initial_promise.send :resolve, {food: 'taco'} # first request completes
        expect(@food).to eq 'taco'
        @second_promise.send :resolve, {topping: 'lettuce'} # second request completes
        expect(@food).to eq 'taco with lettuce'
      end
    end
  end
end
