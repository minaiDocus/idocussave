class GrayLabel
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  field :name,      type: String
  field :site_url,  type: String
  field :logo_url,  type: String
  field :back_url,  type: String
  field :is_active, type: Boolean, default: true

  validates_presence_of :name, :organization_id, :site_url, :logo_url
  validates_uniqueness_of :name

  slug :name

  belongs_to :organization

  def link_to_session_create
    "/gr/sessions/#{self.slug}/create"
  end
end
