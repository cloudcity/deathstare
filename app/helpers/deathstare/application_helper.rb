module Deathstare
  module ApplicationHelper
    # Return HTML to support a pretty-printed date.
    #
    # @param date [DateTime] some date in the past
    # @return [String] HTML span representing a friendly-formatted date
    def relative_date date
      %[<span class="relative-date" title="#{date.iso8601}">#{date}</span>].html_safe
    end

    # @param test_session [TestSession] test session
    # @return [String] Friendly list of suite classes, or "All"
    def suites test_session
      test_session.suite_names.join(', ').tap{|t| t.prepend('All') if t.empty? }
    end
  end
end
