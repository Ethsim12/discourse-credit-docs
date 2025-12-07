# frozen_string_literal: true

class UserCredits < ActiveRecord::Base
  self.table_name = "user_credits"

  belongs_to :user

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  # Optional, if you have these columns:
  # validates :lifetime_earned, :lifetime_spent,
  #           numericality: { greater_than_or_equal_to: 0 }

  # Convenience: ensure a record exists and initialise counters
  def self.ensure_for(user)
    find_or_create_by!(user_id: user.id) do |uc|
      uc.balance          ||= 0
      uc.lifetime_earned  ||= 0 if uc.respond_to?(:lifetime_earned)
      uc.lifetime_spent   ||= 0 if uc.respond_to?(:lifetime_spent)
    end
  end

  # --- Canonical methods used by CreditsService ---

  def add!(amount)
    amount = amount.to_i
    raise ArgumentError, "amount must be >= 0" if amount.negative?

    attrs = { balance: balance + amount }
    if respond_to?(:lifetime_earned) && lifetime_earned
      attrs[:lifetime_earned] = lifetime_earned + amount
    end

    update!(attrs)
  end

  def subtract!(amount)
    amount = amount.to_i
    raise ArgumentError, "amount must be >= 0" if amount.negative?
    raise CreditsService::NotEnoughCreditsError if amount > balance

    attrs = { balance: balance - amount }
    if respond_to?(:lifetime_spent) && lifetime_spent
      attrs[:lifetime_spent] = lifetime_spent + amount
    end

    update!(attrs)
  end

  # --- Backwards-compat: keep your old method names too ---

  alias_method :add_credits, :add!
  alias_method :spend_credits, :subtract!
end
