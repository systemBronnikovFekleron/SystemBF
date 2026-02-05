class CreateWikiPages < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.references :parent, foreign_key: { to_table: :wiki_pages }
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.integer :position, default: 0
      t.integer :status, default: 0
      t.timestamps
    end

    add_index :wiki_pages, :slug, unique: true
    add_index :wiki_pages, :status
    add_index :wiki_pages, :position
  end
end
