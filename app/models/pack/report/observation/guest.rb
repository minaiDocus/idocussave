# -*- encoding : UTF-8 -*-
class Pack::Report::Observation::Guest < ActiveRecord::Base
  belongs_to :observation, class_name: 'Pack::Report::Observation', inverse_of: :guests
end
