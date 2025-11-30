# frozen_string_literal: true

class CreateUserCredits < ActiveRecord::Migration[7.0]
  def change
    create_table :user_credits do |t|
      t.integer :user_id, null: false
      t.integer :balance, null: false, default: 0
      t.integer :lifetime_earned, null: false, default: 0
      t.integer :lifetime_spent, null: false, default: 0

      t.timestamps
    end

    add_index :user_credits, :user_id, unique: true
  end
end
