module Account::ProfileHelper
  def ibiza_state(ibiza)
    t('mongoid.models.ibiza.attributes.state_value.'+(ibiza.try(:state) || 'none'))
  end

  def ibiza_state_label(ibiza)
    case ibiza.try(:state)
      when 'waiting'
        'label-warning'
      when 'valid'
        'label-success'
      when 'invalid'
        'label-important'
      else
        ''
    end
  end

  def file_type_to_deliver_options
    [
        ['PDF et TIFF', ExternalFileStorage::ALL_TYPES],
        ['PDF', ExternalFileStorage::PDF],
        ['TIFF', ExternalFileStorage::TIFF]
    ]
  end

  def file_type_to_deliver(number)
    if number == ExternalFileStorage::ALL_TYPES
      'PDF et TIFF'
    elsif number == ExternalFileStorage::PDF
      'PDF'
    elsif number == ExternalFileStorage::TIFF
      'TIFF'
    else
      ''
    end
  end
end
