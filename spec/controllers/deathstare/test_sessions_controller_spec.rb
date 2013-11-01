require 'spec_helper'

module Deathstare
  describe TestSessionsController do
    routes { Deathstare::Engine.routes }

    describe "without a session" do
      it 'starts a test session' do
        params = {'devices'=>'10', 'run_time'=>'0', 'base_url'=>'http://test.host', 'workers'=>1}
        test_session = FactoryGirl.create(:test_session, params)
        expect(TestSession).to receive(:create).with(params).and_return(test_session)
        expect(test_session).to receive(:enqueue)
        post :create, test_session:params
        expect(response).to redirect_to(test_session_path(test_session.id))
      end

      it 'lists test sessions' do
        get :index
        expect(response).to render_template('index')
      end

      it 'clears test sessions' do
        3.times { FactoryGirl.create(:test_session, end_point:nil) }
        post :clear
        expect(TestSession.count).to eq 0
        expect(response).to redirect_to(root_path)
      end
    end

    describe "with a session" do
      before do
        @params = {'devices'=>'10', 'run_time'=>'0', 'base_url'=>'http://test.host', 'workers'=>1}
        @test_session = FactoryGirl.create(:test_session, @params)
        allow(TestSession).to receive(:find).and_return(@test_session)
      end

      it 'displays a test session' do
        expect(LibratoApp).to receive(:create_or_update_instruments).
          with(@test_session.suite_names)
        get :show, id:@test_session.id
        expect(response).to render_template('show')
      end

      it 'cancels a test session' do
        expect(@test_session).to receive(:cancel_session).and_return(true)
        post :cancel, id:@test_session.id
        expect(response).to redirect_to(test_session_path(@test_session.id))
      end

      it 'destroys a test session' do
        expect(@test_session).to receive(:destroy)
        delete :destroy, id:@test_session.id
        expect(response).to redirect_to(test_sessions_path)
      end
    end
  end
end
