class AddResultCountToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :result_count, :integer, default:0
  end
end
