class SpecSession < Deathstare::UpstreamSession
  def self.with_token token
    session = create
    session.info.session_token = token
    session
  end

  def generate
    info.session_token = SecureRandom.uuid
  end

  def session_params
    {session_token:info.session_token}
  end

  session_state(:logged_in) do |client|
    client.http(:post, '/api/login', session_params).
      then {|r| info.session_token = r[:response][:session_token] }
  end
end
