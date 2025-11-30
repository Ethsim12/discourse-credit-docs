# name: discourse-credit-docs
# about: Adds a basic credit system for gated downloads
# version: 0.0.1
# authors: Ethan Mees
# url: https://github.com/ethanmees/discourse-credit-docs

enabled_site_setting :credit_docs_enabled

after_initialize do
  # Make sure our models and service are loaded
  %w[
    ../app/models/user_credits.rb
    ../app/models/credit_transaction.rb
    ../app/services/credits_service.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  # 1) Add credit_balance to current user serializer
  add_to_serializer(:current_user, :credit_balance) do
    if SiteSetting.credit_docs_enabled
      UserCredits.ensure_for(object).balance
    else
      0
    end
  end

  # 2) Reward credits when a post is approved
  #
  # For now: very simple rule
  # - only in enabled plugin
  # - always gives SiteSetting.credit_docs_default_reward credits
  #
  DiscourseEvent.on(:post_approved) do |post, _moderator|
    next unless SiteSetting.credit_docs_enabled
    next unless post.user.present?

    reward = SiteSetting.credit_docs_default_reward.to_i
    next if reward <= 0

    CreditsService.award!(
      post.user,
      reward,
      tx_type: "upload_reward",
      post: post,
      metadata: { "source" => "post_approved" }
    )
  end

  # Extend the DownloadController to require credits if attachment is gated
  require_dependency 'download_controller'

  class ::DownloadController
    before_action :check_credit_docs, only: [:show]

    def check_credit_docs
      return unless SiteSetting.credit_docs_enabled
      return unless current_user.present?

      upload = Upload.find_by(id: params[:id])
      return unless upload.present?

      # Check if this upload is gated
      doc = CreditDocument.find_by(upload_id: upload.id)
      return if doc.blank? || doc.free? # Not gated or 0 cost

      # Uploader themselves should not pay
      return if current_user.id == doc.uploader_id

      # Optional: bypass if user is staff or in free-access group
      free_group_name = SiteSetting.credit_docs_allow_free_for_group
      if current_user.staff? || (free_group_name.present? &&
          Group.find_by(name: free_group_name)&.users&.exists?(id: current_user.id))
        return
      end

      # Attempt to spend credits
      CreditsService.spend!(
        current_user,
        doc.cost,
        tx_type: "download_cost",
        upload: upload,
        post: doc.post,
        metadata: { reason: "Attempted gated download" }
      )
    rescue CreditsService::NotEnoughCreditsError
      # Block the download with 403 Forbidden
      render plain: "❌ You do not have enough credits to download this document.", status: :forbidden
    end
  end

  Rails.logger.info("💳 Credit Docs plugin initialized")
end
