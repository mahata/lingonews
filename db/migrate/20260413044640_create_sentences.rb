class CreateSentences < ActiveRecord::Migration[8.1]
  def change
    create_table :sentences do |t|
      t.references :article, null: false, foreign_key: true
      t.integer :position
      t.text :body_en
      t.text :body_ja

      t.timestamps
    end
  end
end
