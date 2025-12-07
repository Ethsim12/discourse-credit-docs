# frozen_string_literal: true

Discourse::Application.routes.append do
  put "/credit-docs/gate" => "credit_docs/gating#update"
end
