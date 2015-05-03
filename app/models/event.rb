# -*- encoding : UTF-8 -*-
class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user

  field :number,         type: Integer
  field :user_code
  field :action
  field :target_id
  field :target_type
  field :target_name
  field :target_attributes, type: Hash, default: {}
  field :path
  field :ip_address

  index({ number: 1 })

  validates_presence_of :number
  validates_uniqueness_of :number

  before_validation :set_number
  before_create :set_user_code

  class << self
    def by_number
      desc(:number)
    end
  end

  def target
    if target_id
      target_type.split('/').each_with_index.map do |klass, i|
        klass.camelcase.constantize.find(target_id.split('/')[i]) rescue nil
      end.compact
    end
  end

private

  def set_number
    self.number ||= DbaSequence.next('Event')
  end

  def set_user_code
    self.user_code ||= self.user.try(:code)
  end
end
