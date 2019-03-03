# -*- encoding : UTF-8 -*-
class DematboxSubscribedService < ApplicationRecord
  belongs_to :dematbox, inverse_of: :services

  validates_presence_of :name, :pid


  def to_s
    "[#{is_for_current_period ? 'C' : 'P'}][G##{group_pid ? group_pid : '-'}#{group_name ? ' ' + group_name : ''}] - [S##{pid} #{name}]"
  end
end
