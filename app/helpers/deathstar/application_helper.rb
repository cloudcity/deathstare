module Deathstar
  module ApplicationHelper
    def signed_in?
      session[:heroku_api_token].present?
    end

    # @param test_session [TestSession] test session
    # @return [String] Friendly list of suite classes, or "All"
    def suites test_session
      test_session.suite_names.join(', ').tap{|t| t.prepend('All') if t.empty? }
    end
  end
end
