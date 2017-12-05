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

ActiveRecord::Schema.define(version: 20171204144739) do

  create_table "coinmarketcaps", force: :cascade do |t|
    t.integer  "ranking"
    t.string   "currency_name"
    t.string   "symbol"
    t.float    "market_cap"
    t.float    "price"
    t.float    "current_supply"
    t.float    "volumn"
    t.float    "hourly_change"
    t.float    "daily_change"
    t.float    "weekly_change"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "fix_prices", force: :cascade do |t|
    t.string   "lineuser_id"
    t.string   "currency_pair"
    t.string   "logic"
    t.float    "setting_price"
    t.string   "status",        default: "ON"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "lineusers", force: :cascade do |t|
    t.string   "userId"
    t.boolean  "following"
    t.boolean  "news"
    t.string   "subscribe"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "price_changes", force: :cascade do |t|
    t.string   "lineuser_id"
    t.string   "currency_pair"
    t.integer  "period_sec",    default: 300
    t.integer  "period_num",    default: 2
    t.float    "range",         default: 0.03
    t.string   "status",        default: "ON"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "lineuser_id"
    t.string   "currency_pair"
    t.string   "status",        default: "ON"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

end
