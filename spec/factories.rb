# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :end_point, class:Deathstare::EndPoint do
    base_url 'http://test.host'
  end
  factory :test_session, class:Deathstare::TestSession do
    devices 1
    run_time 0
    workers 1
    test_names [ 'MySuite#my test' ]
    base_url 'http://test.host'
    end_point
  end
  factory :user, class: Deathstare::User do
    oauth_provider 'heroku'
    uid '123456'
  end
end
