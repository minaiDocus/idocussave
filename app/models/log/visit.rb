# -*- encoding : UTF-8 -*-
class Log::Visit
  include Mongoid::Document
  include Mongoid::Timestamps

  field :path,       type: String
  field :number,     type: Integer
  field :ip_address, type: String

  belongs_to :user, class_name: "User", inverse_of: :log_visits

  validates_presence_of :path, :number

  scope :for_user, lambda { |user| where(:user_id => user.id) }

  before_validation :set_number

  class << self
    def by_number
      desc(:number)
    end
  end

  private

  def set_number
    self.number ||= DbaSequence.next('Log::Visit')
  end
end
