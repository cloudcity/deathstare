require 'spec_helper'
require 'librato/librato_app'

describe LibratoApp do
  class LocationReportingSuite < Deathstar::Suite; end
  class ArthausSuite < Deathstar::Suite; end

  context '.create_or_update_instruments' do
    before do
      @full_response =
        {"query" => {"offset" => 0, "length" => 3, "found" => 3, "total" => 3},
         "instruments" => [
           {"id" => 18926428, "name" => "ArthausSuite", "attributes" => {},
            "streams" => [{"id" => 997854, "metric" => "publish_and_republish_creation.response_time", "type" => "gauge", "source" => "%"},
                          {"id" => 997855, "metric" => "list_upvote_rescind_upvote_fork_get_and_delete_creations.response_time", "type" => "gauge", "source" => "%"},
                          {"id" => 997856, "metric" => "get_user_stats.response_time", "type" => "gauge", "source" => "%"}]},
           {"id" => 18926429, "name" => "LocationReportingSuite", "attributes" => {},
            "streams" => [{"id" => 997857, "metric" => "report_locations.response_time", "type" => "gauge", "source" => "%"},
                          {"id" => 997858, "metric" => "request_heat_map.response_time", "type" => "gauge", "source" => "%"}]}
         ]}
      ArthausSuite.stub(:test_names).and_return(%w(publish_and_republish_creation list_upvote_rescind_upvote_fork_get_and_delete_creations get_user_stats))
      LocationReportingSuite.stub(:test_names).and_return(%w(report_locations request_heat_map))
    end

    context 'instrument exists with all metrics' do
      before do
        expect(LibratoApiV1).to receive(:get).with(url: '/instruments').and_return(@full_response)
      end

      it 'returns live instruments hash' do
        res = LibratoApp.create_or_update_instruments %w(ArthausSuite LocationReportingSuite)
        expect(res).to eq('ArthausSuite' => 18926428, 'LocationReportingSuite' => 18926429)
      end
    end

    context 'instrument exists but is missing metrics' do
      before do
        @full_response['instruments'].pop
        @streams = @full_response['instruments'][0]['streams'].dup.map{|str| str.except('id','type')}
        @full_response['instruments'][0]['streams'].pop
        expect(LibratoApiV1).to receive(:get).with(url: '/instruments').and_return(@full_response)
        expect(LibratoApiV1).to receive(:put).with(url: '/instruments/18926428', body: {streams: @streams}).and_return({})
      end

      it 'returns live instruments hash' do
        res = LibratoApp.create_or_update_instruments 'ArthausSuite'
        expect(res).to eq('ArthausSuite' => 18926428)
      end
    end

    context 'instrument does not exist' do
      before do
        expect(LibratoApiV1).to receive(:get).with(url: '/instruments').and_return('instruments'=>[])
        expect(LibratoApiV1).to receive(:post).and_return(headers: {'Location' => '/instruments/123456'})
      end

      it 'creates instruments' do
        res = LibratoApp.create_or_update_instruments 'ArthausSuite'
        expect(res).to eq('ArthausSuite' => 123456)
      end
    end

  end

end
