require 'spec_helper'

module Deathstar
  describe Device do
    before do
      @client = double("Client")
      @promise = double("RequestPromise").tap { |p| p.stub(:then).and_return(@promise) }
      @device = Device.new(@client, client_device: ClientDevice.create(:session_token => 'abc'))
    end

    context 'http requests' do
      it 'GET' do
        expect(@client).to receive(:http).
                             with("get", "/api/creations", session_token: 'abc').
                             and_return(@promise)
        @device.get("/api/creations")
      end
      it 'POST' do
        expect(@client).to receive(:http).
                             with("post", "/api/creations", session_token: 'abc', name: 'taco').
                             and_return(@promise)
        @device.post("/api/creations", name: 'taco')
      end
      it 'PUT' do
        expect(@client).to receive(:http).
                             with("put", "/api/creations/1", session_token: 'abc', name: 'taco').
                             and_return(@promise)
        @device.put("/api/creations/1", name: 'taco')
      end
      it 'PATCH' do
        expect(@client).to receive(:http).
                             with("patch", "/api/creations/1", session_token: 'abc', name: 'taco').
                             and_return(@promise)
        @device.patch("/api/creations/1", name: 'taco')
      end
      it 'DELETE' do
        expect(@client).to receive(:http).
                             with("delete", "/api/creations/1", session_token: 'abc').
                             and_return(@promise)
        @device.delete("/api/creations/1")
      end
    end
  end
end

