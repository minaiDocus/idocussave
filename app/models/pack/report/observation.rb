# -*- encoding : UTF-8 -*-
class Pack::Report::Observation
  include Mongoid::Document

  belongs_to :expense, class_name: "Pack::Report::Expense",            inverse_of: :observation
  has_many   :guests,  class_name: "Pack::Report::Observation::Guest", inverse_of: :observation, dependent: :destroy

  field :comment, type: String

  def to_s
    [
      guests.map { |guest| [guest.first_name,guest.last_name].join(' ') }.join(', '),
      comment.to_s
    ].reject { |e| e.presence.nil? }.
      join(' / ')
  end
end
