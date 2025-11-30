# frozen_string_literal: true

class CreditDocument < ActiveRecord::Base
  self.table_name = "credit_documents"

  belongs_to :upload
  belongs_to :post
  belongs_to :uploader, class_name: "User"

  validates :cost,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :reward,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }

  # Some convenience scopes
  scope :for_post, ->(post) { where(post_id: post.id) }
  scope :for_upload, ->(upload) { find_by(upload_id: upload.id) }

  def free?
    cost.to_i <= 0
  end
end
