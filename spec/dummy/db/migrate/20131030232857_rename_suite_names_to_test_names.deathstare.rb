# This migration comes from deathstare (originally 20131027172940)
class RenameSuiteNamesToTestNames < ActiveRecord::Migration
  def change
    rename_column :deathstar_test_sessions, :suite_names, :test_names
  end
end
