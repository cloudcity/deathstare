class RemoveClientDevices < ActiveRecord::Migration
  def change
    drop_table :deathstare_client_devices
  end
end
