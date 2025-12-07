module CreditDocs
  class GatingController < ::ApplicationController
    requires_plugin "discourse-credit-docs"
    before_action :ensure_staff

    def update
      upload = Upload.find(params[:upload_id])
      cost = params[:cost].to_i

      doc = CreditDocument.find_or_initialize_by(upload_id: upload.id)
      doc.cost = cost
      doc.uploader_id ||= upload.user_id
      doc.post_id ||= upload.post_id
      doc.save!

      render json: success_json
    end
  end
end
