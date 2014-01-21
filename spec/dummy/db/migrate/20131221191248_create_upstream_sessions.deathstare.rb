# This migration comes from deathstare (originally 20131220174843)
class CreateUpstreamSessions < ActiveRecord::Migration
  def change
    create_table :deathstare_upstream_sessions do |t|
      t.belongs_to  :end_point
      t.string :session_state
      t.string :type
      t.text :info
      t.timestamps
    end
    add_index :deathstare_upstream_sessions, [:end_point_id ]
    add_index :deathstare_upstream_sessions, [:type]
    add_index :deathstare_upstream_sessions, [:end_point_id, :session_state],
      name:'deathstare_upstream_end_point_state'
  end
end
