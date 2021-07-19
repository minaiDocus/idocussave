# -*- encoding : UTF-8 -*-
class SgiApiServices::AutoPreAssignedJefacturePiecesValidation
  def self.execute(pieces)
    pieces.each do |piece|
      SgiApiServices::AutoPreAssignedJefacturePiecesValidation.new(piece).execute
    end
  end

  def initialize(piece)
    @piece = piece
    @temp_document = @piece.temp_document
    @raw_preseizure = Jefacture::Document.get(@temp_document.id)
  end

  def execute
    if @raw_preseizure.try(:[], 'piece_number').blank?
      log_document = {
        subject: "[Auto preAssignment Jefacture] - auto jefacture",
        name: "Auto preAssignment Jefacturer",
        error_group: "[Auto preAssignment Jefacture] auto jefacture",
        erreur_type: "Auto jefacture",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          piece_id: @piece.id,
          error: 'raw preseizure blank',
          retrun: @raw_preseizure.to_s,
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    else
      if @temp_document.present? && @raw_preseizure['piece_number'] && @piece.preseizures.empty? && @piece.temp_preseizures.empty? && !@piece.is_awaiting_pre_assignment?
        temp_preseizure = Pack::Report::TempPreseizure.new
        temp_preseizure.organization     = @piece.user.organization
        temp_preseizure.report           = initialize_report
        temp_preseizure.user             = @piece.user
        temp_preseizure.piece            = @piece
        temp_preseizure.raw_preseizure   = @raw_preseizure
        temp_preseizure.position         = @piece.position
        temp_preseizure.is_made_by_abbyy = true
        temp_preseizure.save

        if temp_preseizure.persisted?
          System::Log.info('temp_preseizure', "#{Time.now} - #{@piece.id} - #{@piece.user.organization} - temp preseizure persisted")
          to_validate = false

          if @raw_preseizure['entries'].any?
            @raw_preseizure['entries'].each do |entry|
              to_validate = true if entry[:account].blank? || @piece.detected_third_party_id == 6930 || !check_in_accounting_plan(entry[:account])
            end
          else
            log_document = {
              subject: "[Auto preAssignment Jefacture] - auto jefacture",
              name: "Auto preAssignment Jefacturer",
              error_group: "[Auto preAssignment Jefacture] auto jefacture",
              erreur_type: "Auto jefacture",
              date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
              more_information: {
                piece_id: @piece.id,
                error: 'No entries found',
                retrun: @raw_preseizure.to_s,
              }
            }

            ErrorScriptMailer.error_notification(log_document).deliver

            return false
          end

          if to_validate
            temp_preseizure.waiting_validation
          else
            staffing = StaffingFlow.new({ kind: 'jefacture', params: { temp_preseizure_id: temp_preseizure.id, piece_id: @piece.id, raw_preseizure: @raw_preseizure } }).save

            temp_preseizure.is_valid
          end
        else
          System::Log.info('temp_preseizure', "#{Time.now} - #{@piece.id} - #{@piece.user.organization.id} - errors : #{temp_preseizure.errors.full_messages}")
        end
      end
    end

    true
  end

  private

  def initialize_report
    name = @piece.pack.name.sub(' all', '')
    report = Pack::Report.where(name: name).first

    unless report
      report = Pack::Report.new
      report.organization = @piece.user.organization
      report.user         = @piece.user
      report.type         = 'FLUX'
      report.name         = name
      report.save
    end

    report
  end

  def check_in_accounting_plan(third_party_account)
    found = @piece.user.accounting_plan.active_providers.where(third_party_account: third_party_account).first
    found = @piece.user.accounting_plan.active_customers.where(third_party_account: third_party_account).first if not found
  end
end