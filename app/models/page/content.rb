# -*- encoding : UTF-8 -*-
class Page::Content
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :text, type: String
  field :model, type: Integer, default: 0
  field :position, type: Integer, default: 1
  field :tag, type: String, default: 'info'
  field :is_invisible, type: Boolean, default: false

  # for paragraphe type
  field :thumb, type: String
  field :thumb_info, type: String

  # for pad type
  field :left_link_name, type: String, default: 'Commander'
  field :left_link_url, type: String, default: '/tunnel/order/new'
  field :right_link_name, type: String, default: 'Détails'
  field :right_link_url, type: String, default: '/pages/'

  embedded_in :page, inverse_of: :contents

  validates_presence_of :title, :text

  class << self
    def by_position
      asc(:position).asc(:title)
    end

    def visible
      where(is_invisible: false)
    end

    def invisible
      where(is_invisible: true)
    end

    def distinct_tag
      all.distinct(:tag)
    end
  end
end
