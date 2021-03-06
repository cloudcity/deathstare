require 'spec_helper'

module Deathstare
  describe TestSession do
    it 'marks the session start after devices are initialized' do
      session = FactoryGirl.create(:test_session)
      allow(TestSession).to receive(:find).and_return(session)
      expect(session).to receive(:initialize_devices).ordered
      expect(session).to receive(:start_session).ordered
      TestSession.new.perform('test_session_id' => 1)
    end

    it "spreads suites across workers" do
      session = FactoryGirl.create(:test_session, test_names:%w[ MexicanSuite#taco KoreanSuite#bibimbap ], workers:10)
      TestSession.stub(find:session)
      expect(session).to receive(:initialize_devices).ordered
      5.times do
        expect(MexicanSuite).to receive(:perform_async).ordered
        expect(KoreanSuite).to receive(:perform_async).ordered
      end
      session.perform('test_session_id' => 1)
    end

    it "sets suite_names from test_names" do
      session = TestSession.new
      session.test_names = %w[
      MexicanSuite#taco
      KoreanSuite#bibimbap
      KoreanSuite#kimchi
      ]
      expect(session.suite_names).to eq(%w[ MexicanSuite KoreanSuite ])
      expect(session.suite_classes).to eq([ MexicanSuite, KoreanSuite ])
    end

    it "get suite-specific test names via test_names" do
      session = TestSession.new
      session.test_names = %w[
      MexicanSuite#taco
      KoreanSuite#bibimbap
      KoreanSuite#kimchi
      ]
      expect(session.suite_test_names(MexicanSuite)).to eq(%w[ taco ])
    end

    it "get suite-specific test names via suite_names" do
      session = TestSession.new
      session.suite_names = %w[ MexicanSuite KoreanSuite ]
      expect(session.suite_test_names(KoreanSuite)).to eq(%w[ bibimbap kimchi ])
      expect(session.suite_test_names(JapaneseSuite)).to eq([])
    end

    it "sets test_names from suite_names" do
      session = TestSession.new
      session.suite_names = %w[ MexicanSuite JapaneseSuite ]
      expect(session.test_names).to eq(%w[
                                      MexicanSuite#burrito
                                      MexicanSuite#taco
                                      JapaneseSuite#sushi
                                      JapaneseSuite#teriyaki
                                       ])
    end
  end
end
