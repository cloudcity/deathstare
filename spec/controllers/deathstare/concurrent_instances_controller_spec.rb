require 'spec_helper'

module Deathstare
  describe ConcurrentInstancesController do
    routes { Deathstare::Engine.routes }

    context 'when Heroku token is expired' do
      before do
        session[:user_id] = FactoryGirl.create(:user).id
        controller.stub(:can_control_scalability?).and_return(true)
        allow(HerokuApp).to receive(:get_number_running_sidekiq_workers).and_raise(HerokuApiV3::ExpiredTokenError)
      end

      it 'reports and error in json' do
        get :show, format: 'json'
        expect(response.content_type).to eq('application/json')
        expect(response.status.to_i).to eq(401)
        expect(JSON.parse(response.body)['error']).to match /session has expired/
      end

      it 'redirects in html' do
        get :show, format: 'html'
        expect(response).to redirect_to(not_signed_in_path)
      end

      it 'reports errors in json' do
        get :show, format: 'json'
        expect(Yajl::Parser.parse(response.body)['error']).to match /session has expired/
      end

      it 'signs out session' do
        get :show, format: 'json'
        expect(session[:heroku_api_token]).to be_nil
      end
    end

  end
end
