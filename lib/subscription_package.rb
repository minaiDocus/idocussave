class SubscriptionPackage
  PACKAGES_LIST = [:ido_classique, :ido_mini, :ido_micro, :ido_x].freeze
  OPTIONS_LIST  = [:mail_option, :retriever_option, :pre_assignment_option].freeze

  class << self
    def price_of(package_or_option, reduced=false)
      signing_piece_price  = 1
      pre_assignment_price = 9

      # package_price + signing_piece_price + pre_assignment_price
      case package_or_option
        #packages
        when :ido_classique
          10 + signing_piece_price
        when :ido_x
          5
        when :ido_mini
          10 + signing_piece_price
        when :ido_micro
          10
        #options
        when :mail_option
          10
        when :retriever_option
          reduced ? 3 : 5
        when :pre_assignment_option
          5
        else
          0
      end
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
        else
          { retriever: true, upload: true, email: true, scan: true }
      end
    end

    def infos_of(package_or_option)
      case package_or_option
        #packages
        when :ido_classique
          { label: 'Téléchargement + Pré-saisie comptable', name: 'basic_package_subscription', group: "iDo'Classique" }
        when :ido_x
          { label: 'Factur-X + Pré-saisie comptable', name: 'idox_package_subscription', group: "iDo'X" }
        when :ido_mini
          { label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois', name: 'mini_package_subscription', group: "iDo'Mini" }
        when :ido_micro
          { label: 'Téléchargement + Pré-saisie comptable + Engagement 12 mois', name: 'micro_package_subscription', group: "iDo'Micro" }
        #options
        when :mail_option
          { label: 'Envoi par courrier A/R', name: 'mail_package_subscription', group: "Courrier" }
        when :retriever_option
          { label: 'Récupération banque + Factures sur Internet', name: "retriever_package_subscription", group: "Automates" }
        when :pre_assignment_option
          { label: 'Pré-saisie comptable active', name: "pre_assignment_option", group: "Pré-saisie"}
        else
          { label: '', name: '', group: '' }
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