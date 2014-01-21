require 'spec_helper'

module Deathstare
  describe UpstreamSession do

    context "subclassing" do
      it "generation" do
        device = SpecSession.generate FactoryGirl.create(:end_point)
        device.save!
        expect(device).to be_valid
      end

      it "warms up" do
        @session_token = SecureRandom.uuid
        device = SpecSession.generate FactoryGirl.create(:end_point)
        device.save!

        client = double('Client')
        expect(client).to receive(:http).
          with(:post, '/api/login', device.session_params).
            and_return(RequestPromise::Success.new(response: {session_token: @session_token}))

        device.register_and_login(client)
        expect(device.info.session_token).to eq @session_token
      end
    end
  end
end
