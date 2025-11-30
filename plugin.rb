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

  Rails.logger.info("💳 Credit Docs plugin initialized")
end
