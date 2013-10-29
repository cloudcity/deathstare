module Deathstar
  class TestResultsController < ApplicationController
    def index
      @test_session = test_session
      @test_results = @test_session.test_results.order('created_at DESC').paginate(page: params[:page], per_page: 100)
    end

    private

    def test_session
      TestSession.find params[:test_session_id]
    end
  end
end
