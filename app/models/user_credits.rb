# frozen_string_literal: true

class UserCredits < ActiveRecord::Base
  self.table_name = 'user_credits'

  belongs_to :user

  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  # Convenience method: ensure a record exists for any user
  def self.ensure_for(user)
    find_or_create_by!(user_id: user.id)
  end

  # Add credits to the user's balance
  def add_credits(amount)
    update!(
      balance: self.balance + amount,
      lifetime_earned: self.lifetime_earned + amount
    )
  end

  # Spend credits safely
  def spend_credits(amount)
    raise StandardError, "Not enough credits" if self.balance < amount

    update!(
      balance: self.balance - amount,
      lifetime_spent: self.lifetime_spent + amount
    )
  end
end
