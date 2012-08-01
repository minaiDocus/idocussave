# -*- encoding : UTF-8 -*-
class Homepage::Pad
  include Mongoid::Document
  include Mongoid::Timestamps

  field :caption
  field :content
  field :position, :type => Integer, :default => 1
  field :model, :type => Integer, :default => 0
  field :is_invisible, :type => Boolean, :default => false
  field :is_left_active, :type => Boolean, :default => false
  field :left_link_name, :type => String, :default => "Commander"
  field :left_link_url, :type => String, :default => "/tunnel/order/new"
  field :is_right_active, :type => Boolean, :default => false
  field :right_link_name, :type => String, :default => "Détails"
  field :right_link_url, :type => String, :default => "/pages/"

  validates_presence_of :caption
  validates_presence_of :content

  class << self
    def by_position
      asc(:position).asc(:title)
    end

    def visible
      where(:is_invisible => false)
    end

    def invisible
      where(:is_invisible => true)
    end
  end
end
