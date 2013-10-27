module Deathstar
  require 'librato/librato_app'

  class TestSessionsController < ApplicationController
    before_action :load_resource, only: [:show, :stream, :cancel]

    def index
      @test_sessions = TestSession.order(id: :desc).paginate(page:params[:page])
      # TODO: List here links to the show pages of previous runs
    end

    def new
      @test_session = TestSession.new_with_defaults
    end

    # Streaming inspiration taken from:
    # http://ngauthier.com/2013/02/rails-4-sse-notify-listen.html
    # http://tenderlovemaking.com/2012/07/30/is-it-live.html
    def create
      params.permit!

      worker_count = signed_in? \
        ? HerokuApp.get_number_running_sidekiq_workers(session[:heroku_api_token])
        : 1
      if worker_count == 0
        flash[:alert] = "Start at least one instance."
        redirect_to action: 'new'
        return
      end

      @test_session = TestSession.create(params[:test_session])
      if @test_session.persisted?
        @test_session.enqueue worker_count
        redirect_to @test_session
      else
        flash[:error] = "Failed to create session."
        render :new
      end
    end

    def show
      load_resource
      @live_instrument_ids = LibratoApp.create_or_update_instruments(@test_session.suite_names)
      respond_to do |format|
        format.html { render 'show' }
        format.json { render json: @live_instrument_ids }
      end
    end

    def cancel
      # TODO -- a way to recall / abort early for a test run?
    end

    private

    def load_resource
      @test_session = TestSession.find(params[:id])
    end

  end
end
