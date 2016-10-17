# -*- encoding : UTF-8 -*-
class RetrievedData
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :content, type: Hash
  field :error_message
end
