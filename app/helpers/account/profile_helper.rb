# frozen_string_literal: true

module Account::ProfileHelper
  def ibiza_state(state)
    t('activerecord.models.software_ibiza.attributes.states.' + (state.presence || 'none'))
  end

  def ibiza_state_label(state)
    case state
    when 'waiting'
      'badge-warning'
    when 'valid'
      'badge-success'
    when 'invalid'
      'badge-danger'
    else
      ''
    end
  end

  def notification_options
    [
      ['notifier immediatement', 'now'],
      ['notifier dans un récapitulatif journalier', 'delay'],
      ['ne pas notifier', 'none']
    ]
  end
end
