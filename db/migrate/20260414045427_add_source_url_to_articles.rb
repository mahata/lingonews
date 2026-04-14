class AddSourceUrlToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :source_url, :string
    add_index :articles, :source_url, unique: true
  end
end
