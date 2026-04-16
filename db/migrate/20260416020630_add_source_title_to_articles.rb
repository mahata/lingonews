class AddSourceTitleToArticles < ActiveRecord::Migration[8.1]
  def up
    add_column :articles, :source_title, :string

    execute <<~SQL
      UPDATE articles
      SET source_title = title_ja
      WHERE source_title IS NULL
        AND title_ja IS NOT NULL
    SQL
  end

  def down
    remove_column :articles, :source_title
  end
end
