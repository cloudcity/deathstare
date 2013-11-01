# This migration comes from deathstare (originally 20131101020743)
class AddUserIdToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :user_id, :integer
  end
end
