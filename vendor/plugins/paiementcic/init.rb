Dir[File.join(File.dirname(__FILE__), 'lib/*.rb')].each { |file| load file }
require "paiement_cic"
require "paiement_cic_helper"
