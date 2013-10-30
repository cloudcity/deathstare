module Deathstare
  class User < ActiveRecord::Base

    validates :oauth_provider, :uid, presence: true

  end
end
