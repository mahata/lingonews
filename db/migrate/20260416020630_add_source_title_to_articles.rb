class AddSourceTitleToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :source_title, :string
  end
end
