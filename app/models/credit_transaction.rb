# frozen_string_literal: true

class CreditTransaction < ActiveRecord::Base
  self.table_name = "credit_transactions"

  belongs_to :user
  belongs_to :upload, optional: true
  belongs_to :post, optional: true

  # tx_type is a short string like: "earn", "spend", "admin_adjust"
  validates :tx_type, presence: true
  validates :amount, presence: true
  validate :amount_not_zero

  # Positive amount = earn, negative = spend
  scope :earnings, -> { where("amount > 0") }
  scope :spendings, -> { where("amount < 0") }

  def earn?
    amount.to_i > 0
  end

  def spend?
    amount.to_i < 0
  end

  private

  def amount_not_zero
    if amount.to_i == 0
      errors.add(:amount, "must not be zero")
    end
  end
end
