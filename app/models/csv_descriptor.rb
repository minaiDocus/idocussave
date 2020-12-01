class CsvDescriptor < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true


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

  def separator
    comma_as_number_separator ? ',' : '.'
  end
end
