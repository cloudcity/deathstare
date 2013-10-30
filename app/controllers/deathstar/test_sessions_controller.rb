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

    def create
      params.permit!

      worker_count = \
        if Rails.env.development? || Rails.env.test?
          1
        elsif signed_in?
          HerokuApp.get_number_running_sidekiq_workers(current_user)
        else
          0
        end

      if worker_count == 0
        flash[:alert] = "Start at least one worker instance."
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
      if @test_session.cancel
        flash[:notice] = "You've cancelled session ##{@test_session.id}."
      else
        flash[:error] = "Something failed while attempting to cancel session ##{@test_session.id}!"
      end
      redirect_to @test_session
    end

    private

    def load_resource
      @test_session = TestSession.find(params[:id])
    end

  end
end
