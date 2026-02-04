class AddTelegramChatIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :telegram_chat_id, :bigint
    add_index :users, :telegram_chat_id, unique: true
  end
end
