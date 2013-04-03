# -*- encoding : UTF-8 -*-
class Pack::Report::Observation::Guest
  include Mongoid::Document

  belongs_to :observation, class_name: 'Pack::Report::Observation', inverse_of: :guests

  field :first_name, type: String
  field :last_name,  type: String
end
