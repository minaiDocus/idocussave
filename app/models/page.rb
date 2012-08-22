# -*- encoding : UTF-8 -*-
class Page
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :title,            type: String
  field :label,            type: String
  field :text,             type: String,  default: ''
  field :meta_description, type: String
  field :style,            type: String
  field :position,         type: Integer, default: 1
  field :tag,              type: String
  field :is_footer,        type: Boolean, default: false
  field :is_invisible,     type: Boolean, default: false
  field :is_for_preview,   type: Boolean, default: false

  slug :label

  embeds_many :images,   class_name: 'Page::Image'
  embeds_many :contents, class_name: 'Page::Content'

  accepts_nested_attributes_for :images,   reject_if: lambda { |e| e[:name].blank? },  allow_destroy: true
  accepts_nested_attributes_for :contents, reject_if: lambda { |e| e[:title].blank? }, allow_destroy: true

  validates_presence_of :title, :label, :tag

  def image
    images.by_position.first
  end

  class << self
    def in_footer
      where(is_footer: true)
    end
    
    def not_in_footer
      where(is_footer: false)
    end

    def by_position
      asc([:position, :title])
    end

    def visible
      where(is_invisible: false)
    end

    def invisible
      where(is_invisible: true)
    end

    def homepage
      where(tag: /homepage/i).visible.by_position.first
    end

    def all_types
      all.distinct(:tag).reject { |e| e.match /homepage/i }
    end

    def all_first_pages
      pages = all_types.map do |tag|
        Page.where(tag: tag).by_position.visible.first
      end
      pages.sort { |a,b| a.position <=> b.position }
    end

    def find_by_tag param
      all conditions: { tag: param }
    end

    def find_by_slug param
      first conditions: { slug: param }
    end

    def preview
      where(is_for_preview: true)
    end
  end
end
