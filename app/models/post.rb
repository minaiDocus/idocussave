# -*- encoding : UTF-8 -*-
class Post
  include Mongoid::Document

  field :title, :type => Hash
  field :content, :type => Hash

  before_validation :sanitize_i18n_fields

  def i18n_title
    self.title.key?(I18n.locale.to_s) ? self.title[I18n.locale.to_s] : self.title[I18n.default_locale.to_s]
  end

  def i18n_content
    self.content.key?(I18n.locale.to_s) ? self.content[I18n.locale.to_s] : self.content[I18n.default_locale.to_s]
  end

  protected
  def sanitize_i18n_fields
    self.title.delete_if { |key, value| value.blank? }
    self.content.delete_if { |key, value| value.blank? }
  end
end


