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

  def link_to_paper_tracking(paper_process)
    link_to paper_process.tracking_number, "http://www.csuivi.courrier.laposte.fr/suivi/index?id=#{paper_process.tracking_number}"
  end
end
