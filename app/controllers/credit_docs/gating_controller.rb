def update
  upload = Upload.find(params[:upload_id])

  cost = params[:cost].to_i
  if cost.negative?
    return render_json_error("cost must be >= 0", status: 422)
  end

  doc = CreditDocument.find_or_initialize_by(upload_id: upload.id)
  doc.cost = cost
  doc.uploader_id ||= upload.user_id
  doc.post_id ||= upload.post_id

  if doc.save
    render json: success_json
  else
    render_json_error(doc)
  end
end
