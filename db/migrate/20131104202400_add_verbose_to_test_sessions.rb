class AddVerboseToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :verbose, :boolean
  end
end
