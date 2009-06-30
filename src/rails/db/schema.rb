# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090622031130) do

  create_table "apple_push_notifications", :force => true do |t|
    t.string   "device_token"
    t.integer  "errors_nb",       :default => 0
    t.string   "device_language"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "apple_push_notifications", ["device_token"], :name => "index_apple_push_notifications_on_device_token"

  create_table "device_subscriptions", :force => true do |t|
    t.integer  "iphone_id"
    t.integer  "twitter_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iphones", :force => true do |t|
    t.string   "device_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriber_statuses", :force => true do |t|
    t.text     "last_direct_message"
    t.text     "last_mention"
    t.integer  "device_subscription_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twitter_users", :force => true do |t|
    t.string   "username"
    t.binary   "key"
    t.binary   "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
