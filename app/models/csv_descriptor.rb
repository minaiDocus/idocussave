class CsvDescriptor
  include Mongoid::Document
  include Mongoid::Timestamps

  field :comma_as_number_separator, type: Boolean, default: false
  field :directive, type: String, default: ""

  belongs_to :organization
  belongs_to :user

  def directive_to_a
    directive.split('|').map do |e|
      e.scan(/(\w+)-?(.+)?/).first
    end
  end

  def separator
    comma_as_number_separator ? ',' : '.'
  end
end
