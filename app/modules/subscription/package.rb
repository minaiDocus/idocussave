class Subscription::Package
  PACKAGES_LIST = [:ido_classique, :ido_mini, :ido_micro, :ido_nano, :ido_x].freeze
  OPTIONS_LIST  = [:mail_option, :retriever_option, :pre_assignment_option].freeze
  PRICES_LIST   = { ido_classique: 10, ido_x: 5, ido_mini: 10, ido_micro: 10, ido_nano: 5, mail_option: 10, retriever_option: 5, retriever_option_reduced: 3, pre_assignment_option: 9, signing_piece: 1 }

  class << self
    def price_of(package_or_option, reduced=false)
      if package_or_option.to_s == 'retriever_option'
        price = reduced ? Subscription::Package::PRICES_LIST[:retriever_option_reduced] : Subscription::Package::PRICES_LIST[:retriever_option]
      else
        price = Subscription::Package::PRICES_LIST[package_or_option] || 0

        price += Subscription::Package::PRICES_LIST[:signing_piece] if [:ido_classique, :ido_mini].include?(package_or_option)
      end

      price
    end

    def available_options_for(package)
      case package
        when :ido_classique
          { retriever: true, upload: true, email: true, scan: true }
        when :ido_x
          { retriever: false, upload: false, email: false, scan: true }
        when :ido_mini
          { retriever: true, upload: true, email: true, scan: true }
        when :ido_micro
          { retriever: false, upload: true, email: true, scan: true }
        when :ido_nano
          { retriever: false, upload: true, email: true, scan: true }
        else
          { retriever: true, upload: true, email: true, scan: true }
      end
    end

    def infos_of(package_or_option)
      case package_or_option
        #packages
        when :ido_classique
          { label: 'Téléchargement + Pré-saisie comptable', name: 'basic_package_subscription', group: "iDo'Classique", tooltip: "iDo Classique (20€ / mois)  : vous permet de transférer jusqu'à 100 pièces/mois, mutualisation des quotas au niveau du cabinet. Au-delà du quota cabinet cumulé, calcul du dépassement simplifié : 0,25€ ht/facture" }
        when :ido_x
          { label: 'Factur-X + Pré-saisie comptable', name: 'idox_package_subscription', group: "iDo'X", tooltip: "iDo X (10€ / mois, offre de lancement à 5€ / mois) : vous permet de convertir les pièces venues de jefacture.com (Factur-X) en écritures comptables ! Attention, les autres modes d’import de documents (email, upload, appli mobile…) ne sont pas disponibles, seuls les fichiers venant de jefacture.com sont autorisés." }
        when :ido_mini
          { label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois', name: 'mini_package_subscription', group: "iDo'Mini", tooltip: "iDo Mini (10€ / mois)  : vous permet de transférer jusqu'à 300 pièces/trimèstre, mutualisation des quotas au niveau du cabinet. Au-delà du quota cabinet cumulé, calcul du dépassement simplifié : 0,25€ ht/facture" }
        when :ido_micro
          { label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois', name: 'micro_package_subscription', group: "iDo'Micro", tooltip: "iDo Micro (10€ / mois). vous permet de transférer jusqu'à 100 pièces/an et de bénéficier des automates de récupérations bancaires et documentaires pour un engagement de 12 mois. Au-delà de 100 factures, calcul du dépassement simplifié : 0,25€ ht/facture" }
        when :ido_nano
          { label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois', name: 'nano_package_subscription', group: "iDo'Nano", tooltip: "iDo Nano (5€ / mois). vous permet de transférer jusqu'à 100 pièces/an pour un engagement de 12 mois. Au-delà de 100 factures, calcul du dépassement simplifié : 0,25€ ht/facture" }
        #options
        when :mail_option
          { label: 'Envoi par courrier A/R', name: 'mail_package_subscription', group: "Courrier", tooltip: "Courrier (10€ / mois) : vous permet d’adresser vos pièces par courrier à notre centre de numérisation. Disponible pour les forfaits iDo Mini et iDo Classique" }
        when :retriever_option
          { label: 'Récupération banque + Factures sur Internet', name: "retriever_package_subscription", group: "Automates", tooltip: "Automates (5€ / mois) : vous permet de bénéficier des automates de récupération bancaires et documentaires" }
        when :pre_assignment_option
          { label: 'Pré-saisie comptable active', name: "pre_assignment_option", group: "Pré-affectation", tooltip: "Etat de pré-saisie comptable"}
        else
          { label: '', name: '', group: '', tooltip: ''}
      end
    end

    def commitment_of(package)
      #In month; eg: 12 -> means commitment is for 1 years
      case package
        when :ido_classique
          0
        when :ido_x
          0
        when :ido_mini
          12
        when :ido_micro
          12
        when :ido_nano
          12
        else
          0
      end
    end

    def excess_of(package)
      case package
        when :ido_classique
          {
            pieces:         { limit: 100, price: 25, per: :month },
            preassignments: { limit: 100, price: 25, per: :month }
          }
        when :ido_x
          {
            pieces:         { limit: 0, price: 0, per: :month },
            preassignments: { limit: 0, price: 0, per: :month }
          }
        when :ido_mini
          {
            pieces:         { limit: 100, price: 25, per: :quarter },
            preassignments: { limit: 100, price: 25, per: :quarter }
          }
        when :ido_micro
          {
            pieces:         { limit: 100, price: 25, per: :year },
            preassignments: { limit: 100, price: 25, per: :year }
          }
        when :ido_nano
          {
            pieces:         { limit: 100, price: 25, per: :year },
            preassignments: { limit: 100, price: 25, per: :year }
          }
        else
          {
            pieces:         { limit: 100, price: 25, per: :month },
            preassignments: { limit: 100, price: 25, per: :month }
          }
      end
    end

    def discount_billing_of(package, special = false)
      if package == :ido_mini
        [
          { limit: (0..49), subscription_price: 0, retriever_price: 0 },
          { limit: (50..Float::INFINITY), subscription_price: -4, retriever_price: 0 }
        ]
      else
        if special
          [
            { limit: (0..50), subscription_price: -1, retriever_price: 0 },
            { limit: (51..150), subscription_price: -1.5, retriever_price: -0.5 },
            { limit: (151..200), subscription_price: -2, retriever_price: -0.75 },
            { limit: (201..250), subscription_price: -2.5, retriever_price: -1 },
            { limit: (251..350), subscription_price: -3, retriever_price: -1.25 },
            { limit: (351..500), subscription_price: -4, retriever_price: -1.50 },
            { limit: (501..Float::INFINITY), subscription_price: -5, retriever_price: -2 }
          ]
        else
          [
            { limit: (0..75), subscription_price: 0, retriever_price: 0 },
            { limit: (76..150), subscription_price: -1, retriever_price: 0 },
            { limit: (151..250), subscription_price: -1.5, retriever_price: -0.5 },
            { limit: (251..350), subscription_price: -2, retriever_price: -0.75 },
            { limit: (351..500), subscription_price: -3, retriever_price: -1 },
            { limit: (501..Float::INFINITY), subscription_price: -4, retriever_price: -1.25 }
          ]
        end
      end
    end

  end
end