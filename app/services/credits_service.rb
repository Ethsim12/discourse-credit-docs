# frozen_string_literal: true

class CreditsService
  class NotEnoughCreditsError < StandardError; end
  class InvalidAmountError < StandardError; end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Convenience: get or create a credits row for this user
  def user_credits
    UserCredits.ensure_for(user)
  end

  # Return current balance (always safe to call)
  def balance
    user_credits.balance
  end

  #
  # Public API
  #

  # Award credits to the user.
  #
  # amount   - positive Integer number of credits to add
  # tx_type  - short String label, e.g. "earn", "admin_adjust"
  # upload   - optional Upload record (if tied to a document)
  # post     - optional Post record (if tied to a specific post)
  # metadata - optional Hash for extra info (reason, source, etc.)
  #
  def award!(amount,
             tx_type: "earn",
             upload: nil,
             post: nil,
             metadata: {})
    amount = amount.to_i
    raise InvalidAmountError, "amount must be positive" if amount <= 0

    UserCredits.transaction do
      credits = user_credits
      credits.add_credits(amount)

      CreditTransaction.create!(
        user: user,
        tx_type: tx_type,
        amount: amount,
        balance_after: credits.balance,
        upload: upload,
        post: post,
        metadata: metadata
      )
    end
  end

  # Spend credits from the user.
  #
  # Raises NotEnoughCreditsError if balance would go negative.
  #
  def spend!(amount,
             tx_type: "spend",
             upload: nil,
             post: nil,
             metadata: {})
    amount = amount.to_i
    raise InvalidAmountError, "amount must be positive" if amount <= 0

    UserCredits.transaction do
      credits = user_credits

      # Use model-level guard to avoid negative balance
      credits.spend_credits(amount)

      CreditTransaction.create!(
        user: user,
        tx_type: tx_type,
        amount: -amount,              # negative for spending
        balance_after: credits.balance,
        upload: upload,
        post: post,
        metadata: metadata
      )
    end

    true
  rescue StandardError => e
    # Re-map "not enough credits" into a clear error type if you like
    raise NotEnoughCreditsError, e.message if e.is_a?(StandardError)
    raise
  end

  #
  # Class-level convenience helpers
  #

  def self.award!(user, amount, **opts)
    new(user).award!(amount, **opts)
  end

  def self.spend!(user, amount, **opts)
    new(user).spend!(amount, **opts)
  end
end
