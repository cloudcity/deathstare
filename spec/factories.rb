# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :end_point, class:Deathstar::EndPoint do
    base_url 'http://test.host'
  end
  factory :test_session, class:Deathstar::TestSession do
    devices 1
    run_time 0
    base_url 'http://test.host'
    end_point
  end
end
