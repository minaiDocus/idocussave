class AccountingWorkflow::RetrievePreAssignments
  def initialize(process)
    @process = process
    case process
    when 'preseizure'
      @schema =  Nokogiri::XML::Schema(Rails.root.join('lib/xsd/preseizure.xsd'))
    when 'expense'
      @schema =  Nokogiri::XML::Schema(Rails.root.join('lib/xsd/expense.xsd'))
    end
  end

  def self.execute(process)
    new(process).execute
  end

  def self.fetch_all
    %w(preseizure expense).each { |process| execute(process) }
  end

  def execute
    grouped_xml_pieces.each do |pack, xml_pieces|
      period = pack.owner.subscription.find_or_create_period(Date.today)
      document = Reporting.find_or_create_period_document(pack, period)
      report = document.report || create_report(pack, document)

      pre_assignments = get_pre_assignments(xml_pieces, report)

      Billing::UpdatePeriodData.new(period).execute
      Billing::UpdatePeriodPrice.new(period).execute
      next unless is_preseizure?

      if report.preseizures.not_locked.not_delivered.size > 0
        report.remove_delivered_to
      end

      not_blocked_pre_assignments = pre_assignments.select(&:is_not_blocked_for_duplication)
      not_blocked_pre_assignments = not_blocked_pre_assignments.select{|pres| !pres.has_deleted_piece? }
      if not_blocked_pre_assignments.size > 0
        PreAssignment::CreateDelivery.new(not_blocked_pre_assignments, ['ibiza', 'exact_online', 'my_unisoft'], is_auto: true).execute
        PreseizureExport::GeneratePreAssignment.new(not_blocked_pre_assignments).execute
        FileDelivery.prepare(report)
        FileDelivery.prepare(pack)
      end
    end
  end

  private

  def valid_files_path
    Dir.glob(output_path.join('*.xml')).select do |file_path|
      File.atime(file_path) < 2.minutes.ago
    end
  end

  def valid_xml_documents
    valid_files_path.map do |file_path|
      xml_document = Nokogiri::XML(File.read(file_path))
      schema_errors = @schema.validate(xml_document).map(&:to_s)
      if schema_errors.empty?
        [xml_document, file_path]
      else
        move_and_write_errors(file_path, schema_errors)
        nil
      end
    end.compact
  end

  def valid_xml_pieces
    valid_xml_documents.map do |xml_document, file_path|
      xml_piece  = xml_document.at_css('piece')
      piece_name = xml_piece['name'].tr('_', ' ')

      piece = Pack::Piece.where(name: piece_name).first
      journal = piece.user.account_book_types.where(name: piece.pack.name.split[1]).first if piece

      errors = []
      errors << "Piece #{xml_piece['name']} unknown or deleted" unless piece
      errors << "Journal not found" unless journal
      errors << "Piece not awaiting for pre assignment" unless piece.is_awaiting_pre_assignment?
      errors << "Piece #{xml_piece['name']} already pre-assigned" if piece && piece.is_already_pre_assigned_with?(@process)

      if errors.empty?
        [piece, xml_piece, file_path]
      else
        if piece
          # piece.update(is_awaiting_pre_assignment: false)
          piece.not_processed_pre_assignment
        end
        move_and_write_errors(file_path, errors)
        nil
      end
    end.compact
  end

  def grouped_xml_pieces
    valid_xml_pieces.group_by do |piece, _xml_piece, _file_path|
      piece.pack
    end
  end


  def get_pre_assignments(xml_pieces, report)
    pre_assignments = []
    xml_pieces.each do |piece, xml_piece, file_path|
      _ignored = false

      if is_preseizure?
        _ignoring_reason = xml_piece.at_css('ignore').try(:content).to_s.presence

        if _ignoring_reason.present?
          _ignored = true

          Notifications::PreAssignments.new({piece: piece}).notify_pre_assignment_ignored_piece unless piece.is_deleted?
        else
          xml_piece.css('preseizure').each do |data|
            pre_assignments << create_preseizure(piece, report, data)
          end
        end
      elsif is_expense?
        pre_assignments << create_expense(piece, report, xml_piece)
      end

      move_output_xml file_path, (_ignored ? 'ignored' : 'processed')

      delete_input_file_piece piece, report

      _ignored ? piece.ignored_pre_assignment : piece.processed_pre_assignment
      piece.update(pre_assignment_comment: _ignoring_reason)
    end

    pre_assignments
  end


  def create_preseizure(piece, report, data)
    preseizure = Pack::Report::Preseizure.new
    preseizure.report           = report
    preseizure.piece            = piece
    preseizure.user             = piece.user
    preseizure.organization     = piece.user.organization
    preseizure.piece_number     = data.at_css('piece_number').try(:content)
    preseizure.amount           = to_float(data.at_css('amount').try(:content))
    preseizure.currency         = data.at_css('currency').try(:content)
    preseizure.unit             = data.at_css('unit').try(:content)
    preseizure.conversion_rate  = to_float(data.at_css('conversion_rate').try(:content))
    preseizure.third_party      = data.at_css('third_party').try(:content)
    preseizure.date             = data.at_css('date').try(:content).try(:to_date)
    preseizure.deadline_date    = data.at_css('deadline_date').try(:content).try(:to_date)
    preseizure.observation      = data.at_css('observation').try(:content)
    preseizure.position         = piece.position
    preseizure.is_made_by_abbyy = data.at_css('is_made_by_abbyy').try(:content)
    preseizure.save

    data.css('account').each do |xml_account|
      account = Pack::Report::Preseizure::Account.new
      account.type      = Pack::Report::Preseizure::Account.get_type(xml_account['type'])
      account.number    = xml_account['number']
      account.lettering = xml_account['lettering']
      account.save
      preseizure.accounts << account

      xml_account.css('debit,credit').each do |xml_entity|
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

    unless PreAssignment::DetectDuplicate.new(preseizure).execute
      Notifications::PreAssignments.new({pre_assignment: preseizure}).notify_new_pre_assignment_available unless preseizure.has_deleted_piece?
    end

    preseizure
  end

  def create_expense(piece, report, data)
    obs = data.at_css('obs')
    expense                        = Pack::Report::Expense.new
    expense.report                 = report
    expense.piece                  = piece
    expense.user                   = report.user
    expense.organization           = report.organization
    expense.amount_in_cents_wo_vat = to_float(data.at_css('ht').try(:content))
    expense.amount_in_cents_w_vat  = to_float(data.at_css('ttc').try(:content))
    expense.vat                    = to_float(data.at_css('tva').try(:content))
    expense.date                   = data.at_css('date').try(:content).try(:to_date)
    expense.type                   = data.at_css('type').try(:content)
    expense.origin                 = data.at_css('source').try(:content)
    expense.obs_type               = obs['type'].to_i
    expense.position               = piece.position
    expense.save
    observation         = Pack::Report::Observation.new
    observation.expense = expense
    observation.comment = obs.at_css('observation').try(:content)
    observation.save

    obs.css('guest').each do |guest|
      first_name = guest.css('first_name').first.try(:content)
      last_name  = guest.css('last_name').first.try(:content)
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


  def to_float(txt)
    txt.sub(',', '.').to_f if txt.presence
  end


  def is_preseizure?
    @process == 'preseizure'
  end


  def is_expense?
    @process == 'expense'
  end


  def output_path
    is_preseizure? ? AccountingWorkflow.pre_assignments_dir.join('output/preseizures') : AccountingWorkflow.pre_assignments_dir.join('output/expenses')
  end


  def move_and_write_errors(file_path, errors)
    FileUtils.mkdir_p output_path.join('errors')
    FileUtils.mv file_path, output_path.join('errors')

    File.write output_path.join("errors/#{File.basename(file_path, '.xml')}.txt"), errors.join("\n")
  end

  def move_output_xml(file_path, _dir = "processed")
    path = output_path.join("#{_dir}/#{Time.now.strftime('%Y-%m-%d')}")
    FileUtils.mkdir_p path
    FileUtils.mv file_path, path
  end

  def manual_dir
    AccountingWorkflow.pre_assignments_dir.join 'input'
  end

  def delete_input_file_piece(piece, report)
    if(piece.pre_assignment_force_processing?)
      file_name_pattern = manual_dir.join report.type, "#{piece.name.tr(' ', '_')}_recycle.pdf"
    else
      file_name_pattern = manual_dir.join report.type, "#{piece.name.tr(' ', '_')}.pdf"
    end

    File.delete(file_name_pattern) if File.exist? file_name_pattern
  end

end
