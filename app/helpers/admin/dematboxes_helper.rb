# frozen_string_literal: true

module Admin::DematboxesHelper
  def dematbox_state(state)
    case state
    when 'unknown'
      'inconnue'
    when 'verified'
      'ok'
    when 'not_valid'
      'supprimé'
    else
      ''
    end
  end

  def dematbox_type(type)
    if type == 'service'
      'Service'
    elsif type == 'group'
      'Groupe'
    else
      ''
    end
  end

  def dematbox_period(boolean)
    boolean ? 'Actuelle' : 'Précédente'
  end
end
