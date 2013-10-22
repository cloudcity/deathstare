# Helper methods for implementing performance tests. This, together with the {Device} API,
# composes the complete performance test API.
module Deathstar
  module SuiteHelper
    # Repeat a request the given number of times by chaining them to one another.
    # In the provided block, multiple requests must be dependent and the
    # return value must be a promise (e.g. the result of a request).
    #
    # @param count [Integer] number of times to fire the request
    # @param block [Proc] request(s) to be fired
    # @return [RequestPromise] promise that fires on completion of the final request
    def request_times count, &block
      return if count <= 0
      return block.call if count == 1
      (count - 1).times.to_enum.reduce(block.call) { |promise, _| promise.then block }
    end

    # Construct a chain of requests using an array of input values and a block.
    # In the provided block, multiple requests must be dependent and the
    # return value must be a promise (e.g. the result of a request).
    #
    # @param values [Array] values to be passed in to the block
    # @param block [Proc] request(s) to be fired
    # @return [RequestPromise] promise that fires on completion of the final request
    def request_each values, &block
      return if values.empty?
      first_promise = block.call(values.shift)
      values.reduce(first_promise) { |promise, item| promise.then { |r| block.call(item) } }
    end
  end
end

