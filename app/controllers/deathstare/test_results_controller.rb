module Deathstare
  class TestResultsController < BaseController
    def index
      @title = "Result Log"
      @test_session = test_session
      @test_results = @test_session.test_results.order('created_at DESC').paginate(page: params[:page], per_page: 100)
    end

    def errors
      @title = "Error Log"
      @test_session = test_session
      @test_results = @test_session.test_errors.order('created_at DESC').paginate(page: params[:page], per_page: 100)
      render action:'index'
    end

    private

    def test_session
      TestSession.find params[:test_session_id]
    end
  end
end
