# -*- encoding : UTF-8 -*-
module Account::PaperProcessHelper
  def paper_process_type(type)
    if type == 'kit'
      'Kit'
    elsif type == 'receipt'
      'Réception'
    elsif type == 'return'
      'Retour'
    end
  end

  def paper_process_type_options
    [
      ['Kit', 'kit'],
      ['Réception', 'receipt'],
      ['Retour', 'return']
    ]
  end
end
