# -*- encoding : UTF-8 -*-
class Pack::Report::Observation
  include Mongoid::Document

  referenced_in   :expense, class_name: "Pack::Report::Expense",            inverse_of: :observation
  references_many :guests,  class_name: "Pack::Report::Observation::Guest", inverse_of: :observation, dependent: :destroy

  field :comment, type: String

  def to_s
    [
      guests.map { |guest| [guest.first_name,guest.last_name].join(' ') }.join(', '),
      comment.to_s
    ].join(' / ')
  end
end
