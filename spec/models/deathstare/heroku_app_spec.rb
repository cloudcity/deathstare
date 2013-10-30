require 'spec_helper'
module Deathstare
  describe HerokuApp do

    context '.validate_token' do

      it 'returns true for valid token' do
        HerokuApiV3.stub(:get).and_return({"name" => "deathstare"})

        expect(HerokuApp.user_authorized_for_app?(FactoryGirl.create(:user))).to be_true
      end
      it 'returns false for invalid token' do
        HerokuApiV3.stub(:get).and_raise(HerokuApiV3::UnauthorizedAppError)

        expect(HerokuApp.user_authorized_for_app?(FactoryGirl.create(:user))).to be_false
      end

    end

  end
end
