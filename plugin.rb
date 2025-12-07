# frozen_string_literal: true

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
    ../app/models/credit_document.rb
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
  # - only when plugin enabled
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
      metadata: { "source" => "post_approved" },
    )
  end

  # 3) Extend the uploads controller to require credits if an attachment is gated
  begin
    require_dependency "uploads_controller"
  rescue LoadError => e
    Rails.logger.warn(
      "Credit Docs: uploads_controller not found; skipping controller patch (#{e.message})",
    )
  else
    class ::UploadsController
      # show      – main download route
      # show_short / show_secure – short URLs / secure uploads
      before_action :check_credit_docs, only: %i[show show_short show_secure]

      def check_credit_docs
        return unless SiteSetting.credit_docs_enabled
        return unless current_user.present?

        upload = @upload
        upload ||= begin
          if params[:id].present?
            Upload.find_by(id: params[:id])
          elsif params[:sha1].present?
            Upload.find_by(sha1: params[:sha1])
          end
        end

        return unless upload

        # Check if this upload is gated
        doc = CreditDocument.find_by(upload_id: upload.id)
        return if doc.blank? || doc.free? # Not gated or 0 cost

        # Uploader themselves should not pay
        return if current_user.id == doc.uploader_id

        # Optional: bypass if user is staff or in free-access group
        free_group_name = SiteSetting.credit_docs_allow_free_for_group
        if current_user.staff? ||
           (free_group_name.present? &&
             Group.find_by(name: free_group_name)&.users&.exists?(id: current_user.id))
          return
        end

        # Optional: enforce minimum trust level
        min_tl = SiteSetting.credit_docs_min_trust_level.to_i
        if min_tl > 0 && (current_user.trust_level || 0) < min_tl
          render plain: "Your trust level is too low to download this document.", status: :forbidden
          return
        end

        # Attempt to spend credits
        CreditsService.spend!(
          current_user,
          doc.cost,
          tx_type: "download_cost",
          upload: upload,
          post: doc.post,
          metadata: { reason: "Attempted gated download" },
        )
      rescue CreditsService::NotEnoughCreditsError
        # Block the download with 403 Forbidden
        render plain: "You do not have enough credits to download this document.", status: :forbidden
      end
    end
  end

  Rails.logger.info("Credit Docs plugin initialized")
end
