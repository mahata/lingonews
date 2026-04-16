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

ActiveRecord::Schema[8.1].define(version: 2026_04_16_020630) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at", null: false
    t.string "source"
    t.string "source_title"
    t.string "source_url"
    t.string "title_en", null: false
    t.string "title_ja", null: false
    t.datetime "updated_at", null: false
    t.index ["source_url"], name: "index_articles_on_source_url", unique: true
  end

  create_table "sentences", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "body_en", null: false
    t.text "body_ja", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "position"], name: "index_sentences_on_article_id_and_position", unique: true
    t.index ["article_id"], name: "index_sentences_on_article_id"
  end

  add_foreign_key "sentences", "articles"
end
