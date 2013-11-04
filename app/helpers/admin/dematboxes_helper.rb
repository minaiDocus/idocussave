# -*- encoding : UTF-8 -*-
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
  
  def file_size(size_in_octet)
    "%0.3f" % ((size_in_octet * 1.0) / 1048576.0)
  end
end
