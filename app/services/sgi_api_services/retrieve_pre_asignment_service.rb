# -*- encoding : UTF-8 -*-
class SgiApiServices::RetrievePreAsignmentService
  def initialize(preassignment)
    @preassignment = preassignment
  end

  def execute
    @preassignment.each do |pack_id, data_pieces|
      pack     = Pack.find pack_id
      next unless pack

      period   = pack.owner.subscription.find_or_create_period(Date.today)
      document = Reporting.find_or_create_period_document(pack, period)
      report   = document.report || create_report(pack, document)

      pre_assignments = get_pre_assignments(data_pieces, report)

      UpdatePeriodDataService.new(period).execute
      UpdatePeriodPriceService.new(period).execute
      next unless is_preseizure?

      if report.preseizures.not_locked.not_delivered.size > 0
        report.remove_delivered_to
      end

      not_blocked_pre_assignments = pre_assignments.select(&:is_not_blocked_for_duplication)
      not_blocked_pre_assignments = not_blocked_pre_assignments.select{|pres| !pres.has_deleted_piece? }
      if not_blocked_pre_assignments.size > 0
        CreatePreAssignmentDeliveryService.new(not_blocked_pre_assignments, ['ibiza', 'exact_online'], is_auto: true).execute
        GeneratePreAssignmentExportService.new(not_blocked_pre_assignments).execute
        FileDelivery.prepare(report)
        FileDelivery.prepare(pack)
      end
    end
  end

  private

  def is_preseizure?
    @process == 'preseizure'
  end

  def is_expense?
    @process == 'expense'
  end

  def get_pre_assignments(data_pieces, report)
    pre_assignments = []
    data_pieces.each do |datas|
      piece   = Pack::Piece.where(name: datas['piece_name'].tr('_', ' ')).first
      journal = piece.user.account_book_types.where(name: piece.pack.name.split[1]).first if piece

      errors = []
      errors << "Piece #{xml_piece['name']} unknown or deleted" unless piece
      errors << "Journal not found" unless journal
      errors << "Piece #{xml_piece['name']} already pre-assigned" if piece && piece.is_already_pre_assigned_with?(@process)

      if errors.empty?
         _ignored = false

        if is_preseizure?
          _ignoring_reason = datas['ignore'].try(:content).to_s.presence

          if _ignoring_reason.present?
            _ignored = true

            NotifyPreAssignmentIgnoredPiece.new(piece, 5.minutes).execute unless piece.is_deleted?
          else
            datas['preseizure'].each do |data|
              pre_assignments << create_preseizure(piece, report, data)
            end
          end

        elsif is_expense?
          pre_assignments << create_expense(piece, report, xml_piece)
        end

        _ignored ? piece.ignored_pre_assignment : piece.processed_pre_assignment
        piece.update(is_awaiting_pre_assignment: false, pre_assignment_comment: _ignoring_reason)        
      else
        if piece
          piece.update(is_awaiting_pre_assignment: false)
          piece.not_processed_pre_assignment
        end
        nil
      end
    end

    pre_assignments
  end


  def create_preseizure(piece, report, data)
    preseizure = Pack::Report::Preseizure.new
    preseizure.report           = report
    preseizure.piece            = piece
    preseizure.user             = piece.user
    preseizure.organization     = piece.user.organization
    preseizure.piece_number     = data['piece_number'].try(:content)
    preseizure.amount           = to_float(data['amount'].try(:content))
    preseizure.currency         = data['currency'].try(:content)
    preseizure.unit             = data['unit'].try(:content)
    preseizure.conversion_rate  = to_float(data['conversion_rate'].try(:content))
    preseizure.third_party      = data['third_party'].try(:content)
    preseizure.date             = data['date'].try(:content).try(:to_date)
    preseizure.deadline_date    = data['deadline_date'].try(:content).try(:to_date)
    preseizure.observation      = data['observation'].try(:content)
    preseizure.position         = piece.position
    preseizure.is_made_by_abbyy = data['is_made_by_abbyy'].try(:content)
    preseizure.save

    data['account'].each do |xml_account|
      account = Pack::Report::Preseizure::Account.new
      account.type      = Pack::Report::Preseizure::Account.get_type(xml_account['type'])
      account.number    = xml_account['number']
      account.lettering = xml_account['lettering']
      account.save
      preseizure.accounts << account

      xml_account['debit,credit'].each do |xml_entity|
        entry = Pack::Report::Preseizure::Entry.new
        entry.type   = "Pack::Report::Preseizure::Entry::#{xml_entity.name.upcase}".constantize
        entry.number = xml_entity['number'].to_i
        entry.amount = to_float(xml_entity.content)
        entry.save
        account.entries << entry
        preseizure.entries << entry
      end
    end

    preseizure.update(cached_amount: preseizure.entries.map(&:amount).max)

    unless DetectPreseizureDuplicate.new(preseizure).execute
      NotifyNewPreAssignmentAvailable.new(preseizure, 5.minutes).execute unless preseizure.has_deleted_piece?
    end

    preseizure
  end

  def create_expense(piece, report, data)
    obs = data['obs']
    expense                        = Pack::Report::Expense.new
    expense.report                 = report
    expense.piece                  = piece
    expense.user                   = report.user
    expense.organization           = report.organization
    expense.amount_in_cents_wo_vat = to_float(data['ht'].try(:content))
    expense.amount_in_cents_w_vat  = to_float(data['ttc'].try(:content))
    expense.vat                    = to_float(data['tva'].try(:content))
    expense.date                   = data['date'].try(:content).try(:to_date)
    expense.type                   = data['type'].try(:content)
    expense.origin                 = data['source'].try(:content)
    expense.obs_type               = obs['type'].to_i
    expense.position               = piece.position
    expense.save
    observation         = Pack::Report::Observation.new
    observation.expense = expense
    observation.comment = obs['observation'].try(:content)
    observation.save

    obs['guest'].each do |guest|
      first_name = guest['first_name'].first.try(:content)
      last_name  = guest['last_name'].first.try(:content)
      next unless first_name.present? || last_name.present?
      g = Pack::Report::Observation::Guest.new
      g.observation = observation
      g.first_name  = first_name
      g.last_name   = last_name
      g.save
    end

    expense
  end

  def create_report(pack, document)
    journal = pack.owner.account_book_types.where(name: pack.name.split[1]).first
    report = Pack::Report.new
    report.organization = pack.owner.organization
    report.user         = pack.owner
    report.pack         = pack
    report.document     = document
    report.type         = journal.try(:compta_type)
    report.name         = pack.name.sub(/ all\z/, '')
    report.save
    report
  end
end