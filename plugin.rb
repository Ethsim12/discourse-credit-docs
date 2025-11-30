# name: discourse-credit-docs
# about: Adds a basic credit system for gated downloads
# version: 0.0.1
# authors: Ethan Mees
# url: https://github.com/ethanmees/discourse-credit-docs

enabled_site_setting :credit_docs_enabled

after_initialize do
  Rails.logger.info("Credit Docs plugin initialized")
end
