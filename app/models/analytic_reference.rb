class AnalyticReference < ApplicationRecord
  has_many :temp_documents
  has_many :pieces, class_name: 'Pack::Piece'
  has_many :journals, class_name: 'AccountBookType'

  validate :presence_of_one_analysis

  def is_used_by_other_than?(options)
    has_temp_documents  = temp_documents
    has_journals        = journals
    has_pieces          = pieces

    if options[:temp_documents]
      has_temp_documents = has_temp_documents.where.not(id: options[:temp_documents])
    end

    if options[:journals]
      has_journals = has_journals.where.not(id: options[:journals])
    end

    if options[:pieces]
      has_pieces = has_pieces.where.not(id: options[:pieces])
    end

    has_temp_documents.count > 0 || has_pieces.count > 0 || has_journals.count > 0
  end

  def is_used?(option={})
    is_used_by_other_than?({})
  end

  private

  def presence_of_one_analysis
    unless valid_presence?
      errors.add(:a1_name, :blank)
      errors.add(:a1_references, :invalid)
    end
    errors.any?
  end

  def valid_presence?
    a1_valid = a2_valid = a3_valid = true

    3.times do |e|
      i = e+1

      axis = send("a#{i}_name")
      references = send("a#{i}_references")

      valid = false
      if axis.present? && references.present?
        ref = JSON.parse(references)
        ref.each do |r|
          valid ||= r['axis1'].present? || r['axis2'].present? || r['axis3'].present?
        end
      end

      case i
        when 1 
          a1_valid = valid
        when 2
          a2_valid = valid
        when 3
          a3_valid = valid
      end
    end

    a1_valid || a2_valid || a3_valid
  end

  def total_ventilation_rate
    3.times do |e|
      i = e+1

      axis = send("a#{i}_name")
      ref = send("a#{i}_references")

      if axis.present? && ref.present?
        references = JSON.parse(ref)
        total_ventilation = 0

        references.each do |ref|
          total_ventilation += ref['ventilation'].to_f || 0
        end

        errors.add("a#{i}_references".to_sym, 'invalid ventilation') unless total_ventilation == 100
      end
    end
    errors.any?
  end
end
