# -*- encoding : UTF-8 -*-
class SgiApiServices::AutoPreAssignedJefacturePieces
  class << self
    def process(temp_preseizure_id, piece_id, raw_preseizure)
      piece           = Pack::Piece.where(id: piece_id).first
      temp_preseizure = Pack::Report::TempPreseizure.where(id: temp_preseizure_id).first

      return false if !(piece && temp_preseizure)

      temp_preseizure.cloned if execute(piece, raw_preseizure)

      period   = piece.pack.owner.subscription.current_period

      Billing::UpdatePeriodData.new(period).execute
      Billing::UpdatePeriodPrice.new(period).execute
    end

    def execute(piece, raw_preseizure)
      if piece.temp_document.present? && raw_preseizure['piece_number'] && piece.preseizures.empty? && !piece.is_awaiting_pre_assignment?
        piece.waiting_pre_assignment

        preseizure = Pack::Report::Preseizure.new
        preseizure.organization     = piece.user.organization
        preseizure.report           = initialize_report(piece)
        preseizure.user             = piece.user
        preseizure.piece            = piece
        preseizure.date             = raw_preseizure['date']
        preseizure.deadline_date    = raw_preseizure['deadline_date']
        preseizure.piece_number     = raw_preseizure['piece_number']
        preseizure.position         = piece.position
        preseizure.currency         = raw_preseizure['currency']
        preseizure.unit             = raw_preseizure['unit']
        preseizure.third_party      = raw_preseizure['third_party']
        preseizure.observation      = raw_preseizure['observation']
        preseizure.is_made_by_abbyy = true
        preseizure.save

        raw_preseizure['entries'].each do |raw_entry|

          account = Pack::Report::Preseizure::Account.new
          account.preseizure = preseizure
          account.type       = raw_entry['account_type'] # TTC / HT / TVA
          account.number     = raw_entry['account']
          account.save

          entry = Pack::Report::Preseizure::Entry.new
          entry.account    = account
          entry.preseizure = preseizure
          entry.type       = raw_entry['type']
          entry.number     = 0
          entry.amount     = raw_entry['amount'].to_f

          entry.save
        end
        
        if preseizure.persisted?
          System::Log.info('auto_pre_assigned_jefacture_piece', "#{Time.now} - #{piece.id} - #{piece.user.organization} - preseizure persisted")

          piece.processed_pre_assignment
          preseizure.update(cached_amount: preseizure.entries.map(&:amount).max)

          unless PreAssignment::DetectDuplicate.new(preseizure).execute
            PreAssignment::CreateDelivery.new(preseizure, ['ibiza', 'exact_online', 'my_unisoft'], is_auto: true).execute
            PreseizureExport::GeneratePreAssignment.new(preseizure).execute

            Notifications::PreAssignments.new({pre_assignment: preseizure}).notify_new_pre_assignment_available
          end

          true
        else
          System::Log.info('auto_pre_assigned_jefacture_piece', "#{Time.now} - #{piece.id} - #{piece.user.organization.id} - errors : #{preseizure.errors.full_messages}")

          false
        end
      end
    end


    def initialize_report(piece)
      name = piece.pack.name.sub(' all', '')
      report = Pack::Report.where(name: name).first

      unless report
        report = Pack::Report.new
        report.organization = piece.user.organization
        report.user         = piece.user
        report.type         = 'FLUX'
        report.name         = name
        report.save
      end

      report
    end
  end


  def initialize(data_validated)
    @data_validated = data_validated
  end


  def execute
    results = []

    @data_validated.each do |data_validated|
      piece   = Pack::Piece.find data_validated["piece_id"]
      journal = piece.user.account_book_types.where(name: piece.pack.name.split[1]).first if piece

      temp_preseizure = Pack::Report::TempPreseizure.find data_validated["temp_preseizure_id"]

      errors = []
      errors << "Pièce id: #{data_validated["piece_id"]} inconnue ou supprimée" if not piece
      errors << "Journal #{piece.pack.name.split[1]} non trouvé" if not journal
      errors << "Pièce id: #{data_validated["piece_id"]}, nom: #{piece.name} a déjà traitée" if piece && piece.preseizures.any?
      errors << "TempPreseizure #{data_validated["temp_preseizure_id"]} non trouvé" if not temp_preseizure

      if errors.empty?
        temp_preseizure.raw_preseizure['third_party'] = data_validated['third_party']
        temp_preseizure.raw_preseizure['entries']     = data_validated['entries']
        temp_preseizure.save

        staffing = StaffingFlow.new({ kind: 'jefacture', params: { temp_preseizure_id: temp_preseizure.id, piece_id: piece.id, raw_preseizure: temp_preseizure.reload.raw_preseizure } }).save

        temp_preseizure.is_valid

        results << { piece_id: data_validated["piece_id"], piece_name: piece.try(:name), temp_preseizure_id: temp_preseizure.id, message: 'Pré-affectation de jefacture corrigée', errors: []}.with_indifferent_access
      else
        piece.not_processed_pre_assignment

        results << { piece_id: data_validated["piece_id"], piece_name: piece.try(:name), temp_preseizure_id: temp_preseizure.id, message: 'Pré-affectation de jefacture rencontre de problème au niveau de validation', errors: errors}.with_indifferent_access
      end
    end

    results
  end
end