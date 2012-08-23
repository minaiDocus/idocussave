require File.dirname(__FILE__) + '/../../lib/paiement_cic/lib/paiement_cic'
require File.dirname(__FILE__) + '/../../lib/paiement_cic/lib/paiement_cic_helper'

# here the hmac key calculated with the js calculator given by CIC
PaiementCic.hmac_key = "3FA137460D973107A0F0C1E307A816EFDF83989B"
# Here the TPE number
PaiementCic.tpe = "0311056"
# Here the Merchant name
PaiementCic.societe = "grevalis"

if Rails.env.production?
  PaiementCic.target_url = "https://ssl.paiement.cic-banques.fr/paiement.cgi"
else
  PaiementCic.target_url = "https://ssl.paiement.cic-banques.fr/test/paiement.cgi"
end
