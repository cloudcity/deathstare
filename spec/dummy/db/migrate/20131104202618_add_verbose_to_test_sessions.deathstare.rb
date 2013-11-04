# This migration comes from deathstare (originally 20131104202400)
class AddVerboseToTestSessions < ActiveRecord::Migration
  def change
    add_column :deathstare_test_sessions, :verbose, :boolean
  end
end
