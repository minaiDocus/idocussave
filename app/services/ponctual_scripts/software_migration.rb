# -*- encoding : UTF-8 -*-
class PonctualScripts::SoftwareMigration
  class << self
    # migrate user_options to softwares_settings
    def migrate_options
      User.customers.each do |u|
        software = get_software_of(u)

        software.user                               = u
        software.is_ibiza_used                      = u.try(:ibiza_id) ? true : false
        software.is_ibiza_auto_deliver              = u.options.try(:is_auto_deliver)
        software.is_ibiza_compta_analysis_activated = u.options.try(:is_compta_analysis_activated)
        software.is_csv_descriptor_used             = u.options.try(:is_own_csv_descriptor_used) || u.organization.try(:is_csv_descriptor_used)
        software.use_own_csv_descriptor_format      = u.options.try(:is_own_csv_descriptor_used)
        software.is_coala_used                      = u.organization.try(:is_coala_used)
        software.is_quadratus_used                  = u.organization.try(:is_quadratus_used)
        software.save
      end
    end

    def get_software_of(user)
      SoftwaresSetting.find_by_user_id(user.id) || SoftwaresSetting.new
    end


    def migrate_pieces
      # pieces = Pack::Piece.all
      # pieces.each do |pi|
      #   pi.init_tags
      #   pi.save
      #   Pack::Piece.delay_for(10.seconds, queue: :low).generate_thumbs(pi.id)
      #   Pack::Piece.delay_for(10.seconds, queue: :low).extract_content(pi.id)
      # end
    end

    def migrate_packs
    end
  end
end