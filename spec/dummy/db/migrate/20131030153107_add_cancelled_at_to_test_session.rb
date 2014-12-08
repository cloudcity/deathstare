class AddCancelledAtToTestSession < ActiveRecord::Migration
  def change
    add_column :deathstar_test_sessions, :cancelled_at, :timestamp
  end
end
