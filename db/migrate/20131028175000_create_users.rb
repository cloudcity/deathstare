class CreateUsers < ActiveRecord::Migration
  def change
    create_table(:deathstar_users) do |t|
      t.string :oauth_provider, null: false, limit: 255
      t.string :uid, null: false, limit: 255
      t.string :token
      t.string :refresh_token
      t.datetime :token_expires_at
      t.boolean :authorized_for_app, null: false, default: true

      t.timestamps
    end

    add_index :deathstar_users, [:uid, :oauth_provider], unique: true
  end
end
