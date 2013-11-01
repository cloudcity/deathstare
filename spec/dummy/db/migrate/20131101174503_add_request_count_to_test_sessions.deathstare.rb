# This migration comes from deathstare (originally 20131101155520)
class AddRequestCountToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :started_at, :timestamp
  end
end
