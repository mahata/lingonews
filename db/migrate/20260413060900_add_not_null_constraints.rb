class AddNotNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :articles, :title_en, false
    change_column_null :articles, :title_ja, false
    change_column_null :articles, :published_at, false

    change_column_null :sentences, :position, false
    change_column_null :sentences, :body_en, false
    change_column_null :sentences, :body_ja, false

    add_index :sentences, [ :article_id, :position ], unique: true
  end
end
