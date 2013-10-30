# This migration comes from deathstare (originally 20131030231156)
class RenameTablesToDeathstare < ActiveRecord::Migration
  def change
    rename_table :deathstar_client_devices, :deathstare_client_devices
    rename_table :deathstar_end_points, :deathstare_end_points
    rename_table :deathstar_test_results, :deathstare_test_results
    rename_table :deathstar_test_sessions, :deathstare_test_sessions
    rename_table :deathstar_users, :deathstare_users
  end
end
