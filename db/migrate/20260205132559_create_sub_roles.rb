# frozen_string_literal: true

class CreateSubRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :sub_roles do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.integer :level, default: 0
      t.boolean :system_role, default: false
      t.timestamps
    end

    add_index :sub_roles, :name, unique: true
    add_index :sub_roles, :system_role
    add_index :sub_roles, :level

    # Seed 14 базовых ролей
    reversible do |dir|
      dir.up do
        [
          { name: 'guest', display_name: 'Гость', level: 0, system_role: true },
          { name: 'client', display_name: 'Клиент', level: 1, system_role: true },
          { name: 'club_member', display_name: 'Участник клуба', level: 2, system_role: true },
          { name: 'representative', display_name: 'Представитель', level: 3, system_role: true },
          { name: 'trainee', display_name: 'Стажер', level: 4, system_role: true },
          { name: 'instructor_1', display_name: 'Инструктор 1 кат.', level: 5, system_role: true },
          { name: 'instructor_2', display_name: 'Инструктор 2 кат.', level: 6, system_role: true },
          { name: 'instructor_3', display_name: 'Инструктор 3 кат.', level: 7, system_role: true },
          { name: 'specialist', display_name: 'Специалист', level: 8, system_role: true },
          { name: 'expert', display_name: 'Эксперт-Диагност', level: 9, system_role: true },
          { name: 'center_director', display_name: 'Директор Центра', level: 10, system_role: true },
          { name: 'curator', display_name: 'Куратор', level: 11, system_role: true },
          { name: 'manager', display_name: 'Менеджер платформы', level: 12, system_role: true },
          { name: 'admin', display_name: 'Администратор', level: 13, system_role: true }
        ].each do |role_data|
          execute "INSERT INTO sub_roles (name, display_name, level, system_role, created_at, updated_at) VALUES ('#{role_data[:name]}', '#{role_data[:display_name]}', #{role_data[:level]}, true, NOW(), NOW())"
        end
      end
    end
  end
end
