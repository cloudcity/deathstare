require 'spec_helper'

class MexicanSuite < Deathstar::Suite
  test "taco"
  test "burrito"
end

class KoreanSuite < Deathstar::Suite
  test "bibimbap"
  test "kimchi"
end

class JapaneseSuite < Deathstar::Suite
  test "sushi"
  test "teriyaki"
end

describe Deathstar::TestSession do
  it "sets suite_names from test_names" do
    session = Deathstar::TestSession.new
    session.test_names = %w[
      MexicanSuite#taco
      KoreanSuite#bibimbap
      KoreanSuite#kimchi
    ]
    expect(session.suite_names).to eq(%w[ MexicanSuite KoreanSuite ])
    expect(session.suite_classes).to eq([ MexicanSuite, KoreanSuite ])
  end

  it "get suite-specific test names via test_names" do
    session = Deathstar::TestSession.new
    session.test_names = %w[
      MexicanSuite#taco
      KoreanSuite#bibimbap
      KoreanSuite#kimchi
    ]
    expect(session.suite_test_names(MexicanSuite)).to eq(%w[ taco ])
  end

  it "get suite-specific test names via suite_names" do
    session = Deathstar::TestSession.new
    session.suite_names = %w[ MexicanSuite KoreanSuite ]
    expect(session.suite_test_names(KoreanSuite)).to eq(%w[ bibimbap kimchi ])
    expect(session.suite_test_names(JapaneseSuite)).to eq([])
  end

  it "sets test_names from suite_names" do
    session = Deathstar::TestSession.new
    session.suite_names = %w[ MexicanSuite JapaneseSuite ]
    expect(session.test_names).to eq(%w[
                                      MexicanSuite#burrito
                                      MexicanSuite#taco
                                      JapaneseSuite#sushi
                                      JapaneseSuite#teriyaki
                                      ])
  end
end
