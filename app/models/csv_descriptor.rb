class CsvDescriptor < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true


  def directive_to_a
    (directive || '').split('|').map do |e|
      e.scan(/(\w+)-?(.+)?/).first
    end
  end


  def separator
    comma_as_number_separator ? ',' : '.'
  end
end
