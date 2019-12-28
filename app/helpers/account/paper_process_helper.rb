# frozen_string_literal: true

module Account::PaperProcessHelper
  def paper_process_type(type)
    if type == 'kit'
      'Kit'
    elsif type == 'receipt'
      'Réception'
    elsif type == 'scan'
      'Numérisation'
    elsif type == 'return'
      'Retour'
    end
  end

  def paper_process_type_options
    [
      %w[Kit kit],
      %w[Réception receipt],
      %w[Numérisation scan],
      %w[Retour return]
    ]
  end

  def link_to_paper_tracking(paper_process)
    link_to paper_process.tracking_number, "http://www.csuivi.courrier.laposte.fr/suivi/index?id=#{paper_process.tracking_number}", target: '_blank'
  end
end
