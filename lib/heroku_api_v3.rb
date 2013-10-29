module HerokuApiV3
  # Heroku has not yet updated it's Ruby client to the V3 API.
  # According to Brendur Leach, one of the Heroku devs on the API team, making straight HTTPS requests should work fine.
  # The client doesn't add that much.

  class ExpiredTokenError < Exception; end
  class TokenRefreshFailedError < Exception; end
  class UnauthorizedAppError < Exception; end

  def self.get(opts); make_api_request opts.merge(method: :get); end
  def self.put(opts); make_api_request opts.merge(method: :put); end
  def self.patch(opts); make_api_request opts.merge(method: :patch); end
  def self.post(opts); make_api_request opts.merge(method: :post); end
  def self.delete(opts); make_api_request opts.merge(method: :delete); end

  # @abstract Make Request to Heroku V3 API. See docs here: https://devcenter.heroku.com/articles/platform-api-reference
  # @option :url [String] relative URL, e.g. /apps/deathstar (leading slash is optional)
  # @option :method [Symbol] HTTP method, such as :get, :patch, :post, etc.
  # @option :user [User] User record with methods token, token_expires_at and refresh_token.
  # @option :token [String] Access token for Heroku obtained via OAuth
  # @option :body [Hash or String] JSON data to send (for PUT/PATCH/POST)
  # @option :tries [Integer] (optional, default: 1)  Used internall by recursive invocation for token refresh to avoid infinite loop
  # @return [Hash] Ruby hash from JSON response
  # @raise Error if response is not a 2xx status code
  def self.make_api_request(opts)
    raise "Incorrect options for make_api_request" unless [:url, :method].all?{|o|opts[o].present?} && [:token, :user].any?{|o|opts[o].present?}
    opts[:tries] ||= 1
    opts[:token] = token_or_refresh(opts)
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
        if opts[:user].present? && opts[:user].refresh_token.present? && opts[:tries] <= 3
          refresh_token(opts[:user])    # refresh token and retry
          opts[:tries] += 1
          return make_api_request(opts)
        else
          raise ExpiredTokenError
        end
      when 403 # Heroku uses this to indicate the user isn't a member on this app
        raise UnauthorizedAppError
    end
    raise "Response code: #{response.code}, error: #{response.return_message}" if response.code / 100 != 2 # only 2xx response codes please
    JSON.parse response.body
  end

  # Internal helper method to extract a token from the options hash or try to refresh it
  def self.token_or_refresh(opts)
    if (user=opts[:user]).present?
      if user.token_expires_at < Time.now && user.refresh_token.present? && opts[:tries] <= 3
        opts[:tries] += 1
        refresh_token(user)
      end
      user.token
    else
      opts[:token]
    end
  end


  # @param refresh_token [String] a refresh token obtained in a prior OAuth handshake during login
  # @return token [String] A new token
  def self.refresh_token(user)
    # Thanks to help from Brandur, this curl does it:
    # curl -i -X POST -H "Accept: application/vnd.heroku+json; version=3" -H "Content-Type: application/json" https://api.heroku.com/oauth/tokens -d '{"client":{"secret":"..."},"grant":{"type":"refresh_token"},"refresh_token":{"token":"..."}}'
    request = Typhoeus::Request.new(
      'https://api.heroku.com/oauth/tokens',
      method: 'post',
      headers: {Accept: 'application/vnd.heroku+json; version=3', 'Content-Type' => 'application/json'},
      body: {
        refresh_token: {token: user.refresh_token},
        grant: {type: 'refresh_token'},
        client: {secret: Deathstar.config.heroku_oauth_secret}
      }.to_json)
    req_at = Time.now
    response = request.run
    if response.code < 300
      body = JSON.parse response.body
      user.token = body['access_token']['token']
      user.token_expires_at = req_at + body['access_token']['expires_in'].to_i.seconds
      user.refresh_token = body['refresh_token']['token']
      user.save!
    else
      raise TokenRefreshFailedError.new("Status code: #{response.code}, body: #{response.body}")
    end
  end


end
