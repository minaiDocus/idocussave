# -*- encoding : UTF-8 -*-
class DematboxSubscribedService
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :dematbox, inverse_of: :services

  field :name,                  type: String
  field :pid,                   type: String
  field :group_name,            type: String
  field :group_pid,             type: String
  field :is_for_current_period, type: Boolean, default: true

  validates_presence_of :name, :pid

  def to_s
    "[#{is_for_current_period ? 'C' : 'P'}][G##{group_pid ? group_pid : '-'}#{group_name ? ' ' + group_name : ''}] - [S##{pid} #{name}]"
  end
end
