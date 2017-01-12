module Account::ProfileHelper
  def ibiza_state(state)
    t('activerecord.models.ibiza.attributes.states.' + (state.presence || 'none'))
  end


  def ibiza_state_label(state)
    case state
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
end
