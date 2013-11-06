require 'typhoeus'

# Wrap a deferred request in a promise.
module Deathstare
  class RequestPromise
    # @param request [Typhoeus::Request] the request to wrap
    def initialize request
      @request = request
      @completed = false
      @result = nil
      @resolve = []
      @reject = []
      @request.on_complete do |response|
        handle_response response
      end
    end

    # Specify resolve and reject callbacks. Returns a promise.
    # Cannot be called on a completed promise.
    #
    # @param resolve_cb [Proc] Resolve callback
    # @param reject_cb [Proc] Reject callback
    # @param block [Block] Alternate method of specifying resolve callback
    # @return [RequestPromise]
    def then resolve_cb=nil, reject_cb=nil, &block
      # We don't need to support then on a completed promise, as we control the request cycle.
      raise "#{self.class.name} is already completed" if @completed

      resolve_cb ||= block
      @resolve << resolve_cb if resolve_cb
      @reject << reject_cb if reject_cb
      self
    end

    # @param response [Typhoeus::Response]
    # @return [void]
    def handle_response response
      if response.success?
        resolve response
      else
        reject response_details(response)
      end
    end

    private

    # @param r [Typhoeus::Response]
    # @return [String]
    def response_details r
      [
        "HTTP %s %s" % [ r.request.options[:method].upcase, r.request.url],
        "%s %s" % [r.response_code, r.status_message || '(no response)' ],
        "%.2fs connect %.2fs total (%s)" % [ r.connect_time, r.total_time, r.timed_out? ? 'timed out' : 'completed' ],
        r.headers.map{|k,v|"#{k}: #{v}"}.join("\n"),
        "\n", # extra break between headers and body
        r.body
      ].join("\n")
    end

    protected

    # Adopt the callbacks for a dependent promise.
    def adopt promise
      @resolve += promise.instance_variable_get('@resolve')
      @reject += promise.instance_variable_get('@reject')
    end

    # Resolve the promise.
    #
    # @param result [Typhoeus::Response] The result of the request
    # @return [void]
    def resolve result
      raise "already completed" if @completed
      @result = result
      @completed = true
      while cb = @resolve.shift
        result_or_promise = cb.call(@result)
        if result_or_promise.kind_of?(self.class)
          result_or_promise.adopt(self)
          return
        else
          @result = result_or_promise
        end
      end
    end

    # Reject the promise.
    #
    # @param reason [String] The reason for the failure
    # @return [void]
    def reject reason
      raise "already completed" if @completed
      @result = reason
      @completed = true
      while cb = @reject.shift
        result_or_promise = cb.call(@result)
        if result_or_promise.kind_of?(self.class)
          result_or_promise.adopt(self)
          return
        else
          @result = result_or_promise
        end
      end
    end

    # Dummy promise that auto-succeeds.
    class Success < self
      def initialize result
        @result = result
      end

      # @return [RequestPromise]
      def then resolve_cb=nil, reject_cb=nil, &block
        resolve_cb ||= block
        return self unless resolve_cb
        promise_or_result = resolve_cb.call(@result)
        promise_or_result.kind_of?(RequestPromise) ? promise_or_result : self
      end
    end

    # Dummy promise that auto-fails
    class Failure < self
      def initialize reason
        @result = reason
      end

      # @return [RequestPromise]
      def then resolve_cb=nil, reject_cb=nil, &block
        return self unless reject_cb
        promise_or_result = reject_cb.call(@result)
        promise_or_result.kind_of?(RequestPromise) ? promise_or_result : self
      end
    end

  end
end


