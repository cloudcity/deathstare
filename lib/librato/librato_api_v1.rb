module LibratoApiV1
  # Librato's Ruby client doesn't support the full API
  # Missing, for example, is the instruments API

  def self.get(opts); make_api_request opts.merge(method: :get); end
  def self.put(opts); make_api_request opts.merge(method: :put); end
  def self.patch(opts); make_api_request opts.merge(method: :patch); end
  def self.post(opts); make_api_request opts.merge(method: :post); end
  def self.delete(opts); make_api_request opts.merge(method: :delete); end

  # @abstract Make Request to Librato V1 API. See docs here: http://dev.librato.com/v1
  # @option :url [String] relative URL, e.g. /metrics (leading slash is optional)
  # @option :method [Symbol] HTTP method, such as :get, :patch, :post, etc.
  # @option :body [Hash or String] JSON data to send (for PUT/PATCH/POST)
  # @option :with_headers [Booelean] (default: false) If set, will generate a result object like so: {body: ..., headers: {...}}
  # @return [Hash] Ruby hash from JSON response
  # @raise Error if response is not a 2xx status code
  def self.make_api_request(opts)
    request = construct_request(opts)
    response = request.run
    case response.code
      when 400
        {error: 'Error', code: 400}  # Librato sends this when trying to create an instrument with metrics that don't yet exist
      when 404
        {error: 'Not Found', code: 404}
      when 100..299
        body = (response.body.length >= 2 ? JSON.parse(response.body) : {})
        !!opts[:with_headers] ? {body: body, headers: response.headers} : body
      else
        raise "Response code: #{response.code}, error: #{response.return_message}" if response.code / 100 != 2 # only 2xx response codes please
    end
  end

  def self.construct_request(opts)
    raise "Incorrect options for make_api_request" unless [:url, :method].all?(&:present?)
    opts[:url].sub!(%r{\A/+}, '')
    req_params = {method: opts[:method],
                  headers: {Accept: 'application/json'},
                  userpwd: "#{Deathstare.config.librato_email}:#{Deathstare.config.librato_api_token}"}
    opts[:body] = opts[:body].to_json if opts[:body].is_a? Hash
    if opts[:body].present?
      req_params[:body] = opts[:body]
      req_params[:headers][:'Content-Type'] = 'application/json'
    end
    Typhoeus::Request.new("https://metrics-api.librato.com/v1/#{opts[:url]}", req_params)
  end
end
