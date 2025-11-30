# frozen_string_literal: true

class CreateCreditDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_documents do |t|
      t.integer :upload_id, null: false
      t.integer :post_id, null: false
      t.integer :uploader_id, null: false

      t.integer :cost, null: false, default: 1    # credits to download/unlock
      t.integer :reward, null: false, default: 1  # credits awarded for this doc
      t.boolean :auto_rewarded, null: false, default: false

      t.timestamps
    end

    add_index :credit_documents, :upload_id, unique: true
    add_index :credit_documents, :post_id
    add_index :credit_documents, :uploader_id
  end
end
