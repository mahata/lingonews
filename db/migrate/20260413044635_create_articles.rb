class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title_en
      t.string :title_ja
      t.datetime :published_at

      t.timestamps
    end
  end
end
