class CsvDescriptor < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization


  def directive_to_a
    directive.split('|').map do |e|
      e.scan(/(\w+)-?(.+)?/).first
    end
  end


  def separator
    comma_as_number_separator ? ',' : '.'
  end
end
