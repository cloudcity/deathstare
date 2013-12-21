# This migration comes from deathstare (originally 20131221212159)
class RemoveClientDevices < ActiveRecord::Migration
  def change
    drop_table :deathstare_client_devices
  end
end
