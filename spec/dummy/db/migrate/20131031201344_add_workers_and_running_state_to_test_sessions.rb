class AddWorkersAndRunningStateToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :workers, :integer
    add_column :deathstare_test_sessions, :ended_at, :timestamp
    add_index :deathstare_test_sessions, :ended_at
  end
end
