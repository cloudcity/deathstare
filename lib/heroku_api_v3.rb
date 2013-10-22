module HerokuApiV3
  # Heroku has not yet updated it's Ruby client to the V3 API.
  # According to Brendur Leach, one of the Heroku devs on the API team, making straight HTTPS requests should work fine.
  # The client doesn't add that much.

  class ExpiredTokenError < Exception; end
  class UnauthorizedAppError < Exception; end

  def self.get(opts); make_api_request opts.merge(method: :get); end
  def self.put(opts); make_api_request opts.merge(method: :put); end
  def self.patch(opts); make_api_request opts.merge(method: :patch); end
  def self.post(opts); make_api_request opts.merge(method: :post); end
  def self.delete(opts); make_api_request opts.merge(method: :delete); end

  # @abstract Make Request to Heroku V3 API. See docs here: https://devcenter.heroku.com/articles/platform-api-reference
  # @option :url [String] relative URL, e.g. /apps/deathstar (leading slash is optional)
  # @option :method [Symbol] HTTP method, such as :get, :patch, :post, etc.
  # @option :token [String] Access token for Heroku obtained via OAuth
  # @option :body [Hash or String] JSON data to send (for PUT/PATCH/POST)
  # @return [Hash] Ruby hash from JSON response
  # @raise Error if response is not a 2xx status code
  def self.make_api_request(opts)
    raise "Incorrect options for make_api_request" unless [:url, :method, :token].all?(&:present?)
    req_params = {method: opts[:method],
                  headers: {Accept: 'application/vnd.heroku+json; version=3', Authorization: "Bearer #{opts[:token]}"} }
    opts[:body] = opts[:body].to_json if opts[:body].is_a? Hash
    if opts[:body].present?
      req_params[:body] = opts[:body]
      req_params[:headers][:'Content-Type'] = 'application/json'
    end
    request = Typhoeus::Request.new("https://api.heroku.com/#{opts[:url]}", req_params)
    response = request.run
    case response.code
      when 401 # Heroku uses this to indicate expired tokens
        raise ExpiredTokenError
      when 403 # Heroku uses this to indicate the user isn't a member on this app
        raise UnauthorizedAppError
    end
    raise "Response code: #{response.code}, error: #{response.return_message}" if response.code / 100 != 2 # only 2xx response codes please
    JSON.parse response.body
  end
end
