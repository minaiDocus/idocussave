# -*- encoding : UTF-8 -*-
class Page::Image
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :description,  type: String,  default: ''
  field :link,         type: String,  default: '/pages/'
  field :position,     type: Integer, default: 1
  field :is_invisible, type: Boolean, default: false

  validates_presence_of :name

  embedded_in :page, inverse_of: :images

  class << self
    def by_position
      asc([:position, :name])
    end

    def visible
      where(is_invisible: false)
    end

    def invisible
      where(is_invisible: true)
    end
  end
end
