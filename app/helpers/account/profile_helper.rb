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
        ['Tous', ExternalFileStorage::ALL_TYPES],
        ['PDF', ExternalFileStorage::PDF],
        ['TIFF', ExternalFileStorage::TIFF]
    ]
  end

  def file_type_to_deliver(number)
    if number == ExternalFileStorage::ALL_TYPES
      'Tous'
    elsif number == ExternalFileStorage::PDF
      '.pdf'
    elsif number == ExternalFileStorage::TIFF
      '.tiff'
    else
      ''
    end
  end
end