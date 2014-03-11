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

ActiveRecord::Schema.define(version: 20140307201936) do

  create_table "punches", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "entrance",   default: true
    t.text     "comment"
    t.datetime "punched_at"
  end

  add_index "punches", ["entrance"], name: "index_punches_on_entrance", using: :btree
  add_index "punches", ["punched_at"], name: "index_punches_on_punched_at", using: :btree
  add_index "punches", ["user_id"], name: "index_punches_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",           default: false
    t.boolean  "hidden",          default: false
    t.string   "token"
    t.string   "shifts",          default: "---\n- 480\n- 720\n- 0\n- 840\n- 1080\n- 0\n", null: false
    t.integer  "daily_goal",      default: 8,                                              null: false
  end

end
