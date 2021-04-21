# -*- encoding : UTF-8 -*-
class Archive::AlreadyExist < ApplicationRecord
  self.table_name = 'archive_already_exist'

  belongs_to :temp_document, optional: true

  def get_access_url
    "/account/documents/exist_document/#{id}/download/" + '?token=' + get_token
  end

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))

      token
    end
  end
end