class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.text :content
      t.references :author, foreign_key: { to_table: :users }
      t.integer :article_type, default: 0
      t.integer :status, default: 0
      t.boolean :featured, default: false
      t.datetime :published_at
      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, :article_type
    add_index :articles, :status
    add_index :articles, :featured
  end
end
