# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141203233800) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "deathstare_end_points", force: true do |t|
    t.string   "base_url"
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deathstare_end_points", ["base_url"], name: "index_end_points_on_base_url", unique: true, using: :btree

  create_table "deathstare_test_results", force: true do |t|
    t.integer  "test_session_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "suite_name"
    t.string   "test_name"
    t.text     "messages"
    t.boolean  "error",           default: false
  end

  add_index "deathstare_test_results", ["test_session_id", "created_at"], name: "index_test_results_on_test_session_id_and_created_at", using: :btree
  add_index "deathstare_test_results", ["test_session_id", "error"], name: "index_deathstare_test_results_on_test_session_id_and_error", using: :btree
  add_index "deathstare_test_results", ["test_session_id"], name: "index_test_results_on_test_session_id", using: :btree

  create_table "deathstare_test_sessions", force: true do |t|
    t.string   "base_url",                  null: false
    t.integer  "devices",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
    t.string   "test_names",   default: [], null: false, array: true
    t.integer  "end_point_id"
    t.integer  "run_time"
    t.datetime "cancelled_at"
    t.integer  "workers"
    t.datetime "ended_at"
    t.integer  "user_id"
    t.datetime "started_at"
    t.boolean  "verbose"
    t.integer  "result_count", default: 0
  end

  add_index "deathstare_test_sessions", ["ended_at"], name: "index_deathstare_test_sessions_on_ended_at", using: :btree

  create_table "deathstare_upstream_sessions", force: true do |t|
    t.integer  "end_point_id"
    t.string   "session_state"
    t.string   "type"
    t.text     "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deathstare_upstream_sessions", ["end_point_id", "session_state"], name: "deathstare_upstream_end_point_state", using: :btree
  add_index "deathstare_upstream_sessions", ["end_point_id"], name: "index_deathstare_upstream_sessions_on_end_point_id", using: :btree
  add_index "deathstare_upstream_sessions", ["type"], name: "index_deathstare_upstream_sessions_on_type", using: :btree

  create_table "deathstare_users", force: true do |t|
    t.string   "oauth_provider",                    null: false
    t.string   "uid",                               null: false
    t.string   "token"
    t.string   "refresh_token"
    t.datetime "token_expires_at"
    t.boolean  "authorized_for_app", default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deathstare_users", ["uid", "oauth_provider"], name: "index_deathstare_users_on_uid_and_oauth_provider", unique: true, using: :btree

end
