# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_13_044640) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "title_en"
    t.string "title_ja"
    t.datetime "updated_at", null: false
  end

  create_table "sentences", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "body_en"
    t.text "body_ja"
    t.datetime "created_at", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_sentences_on_article_id"
  end

  add_foreign_key "sentences", "articles"
end
