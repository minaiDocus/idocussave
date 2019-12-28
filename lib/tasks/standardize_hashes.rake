namespace :standardize_hashes do
  task ibiza: :environment do
    class Ibiza < ApplicationRecord
      serialize :description
      serialize :piece_name_format
    end

    Ibiza.find_each do |ibiza|
      ibiza.update(description: ibiza.description.to_h) if ibiza.description.is_a?(ActionController::Parameters)
      ibiza.update(piece_name_format: ibiza.piece_name_format.to_h) if ibiza.piece_name_format.is_a?(ActionController::Parameters)
    end
  end
end