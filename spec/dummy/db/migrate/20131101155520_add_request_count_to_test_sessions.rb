class AddRequestCountToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :started_at, :timestamp
  end
end
