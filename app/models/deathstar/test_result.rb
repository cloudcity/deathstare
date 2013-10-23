require 'yajl'

class Deathstar::TestResult < ActiveRecord::Base
  belongs_to :test_session
  validates :test_session_id, :suite_name, :test_name, presence: true

  class << self
    # @param suite_name [String] Suite name
    # @param test_name [String] Test name
    # @param response [Hash] response hash from DSClient
    def from_response suite_name, test_name, response
      new(
        suite_name: suite_name,
        test_name: test_name,
        messages: response_message(response).tap {|msg| puts(msg) if Rails.env.development? }
      )
    end

    # Create a log message given a response Hash.
    def response_message response
      "%s %s: %s %s (%f)\n%s" % [
        *response[:_response_meta].slice(
          :request_method, :request_url, :status_code, :status_message, :total_time
        ).values,
        Yajl::Encoder.encode(response.except(:_response_meta))
      ]
    end
  end

  # @return [String] information about the request status and completion time
  def log_line
    @log_line ||= messages.split("\n",2)[0]
  end

  # @return [String] raw JSON response from DSAPI
  def raw_response
    @raw_response ||= messages.split("\n",2)[1]
  end

  # @return [Hash] decoded JSON response with symbolized keys
  def response
    Yajl::Parser.parse(raw_response, symbolize_keys:true)
  end
end
