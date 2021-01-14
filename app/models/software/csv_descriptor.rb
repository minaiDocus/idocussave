class Software::CsvDescriptor < ApplicationRecord
  include Interfaces::Software::Configuration

  belongs_to :owner, polymorphic: true

  validates_inclusion_of :auto_deliver, in: [-1, 0, 1]

  def directive_to_a
    directive.to_s.split('|').map do |e|
      e.scan(/(\w+)-?(.+)?/).first
    end
  end

  def directive_to_h
    directives_a = []

    _directive = directive.to_s.gsub('|separator', '&sep').gsub('|space', '&spa')

    _directive.to_s.split('|').each do |e|
      scaner = e.scan(/(\w+)-?([^&]+)?[&]?(.+)?/).flatten
      directives_a << { name: scaner.first, separator: (scaner.third != 'spa'), format: scaner.second.to_s }
    end

    directives_a
  end

  def use_own_format?
    use_own_csv_descriptor_format
  end

  def separator
    comma_as_number_separator ? ',' : '.'
  end
end
