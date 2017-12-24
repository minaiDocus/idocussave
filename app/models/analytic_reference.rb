class AnalyticReference < ActiveRecord::Base
  belongs_to :temp_document
  # or
  belongs_to :piece, class_name: 'Pack::Piece'
end
