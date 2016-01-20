# -*- encoding : UTF-8 -*-
class PrepaCompta::PreAssignPiece
  def initialize(process)
    @process = process
    case process
      when 'abbyy_preseizure'
        @schema =  Nokogiri::XML::Schema(Rails.root.join('lib/xsd/abbyy_preseizure.xsd'))
      when 'preseizure'
        @schema =  Nokogiri::XML::Schema(Rails.root.join('lib/xsd/preseizure.xsd'))
      when 'expense'
        @schema =  Nokogiri::XML::Schema(Rails.root.join('lib/xsd/expense.xsd'))
    end
  end

  class << self
    def execute(process)
      new(process).execute
    end

    def fetch_all
      %w(preseizure abbyy_preseizure expense).each { |process| execute(process) }
    end
  end

  def execute
    grouped_xml_pieces.each do |pack, xml_pieces|
      period = pack.owner.subscription.find_or_create_period(Time.now)
      document = Reporting.find_or_create_period_document(pack, period)
      report = document.report || create_report(pack, document)

      pre_assignments = get_pre_assignments(xml_pieces, report)

      UpdatePeriodDataService.new(period).execute
      UpdatePeriodPriceService.new(period).execute
      if is_a_preseizure?
        if report.preseizures.not_delivered.not_locked.count > 0
          report.update_attribute(:is_delivered, false)
        end
        CreatePreAssignmentDeliveryService.new(pre_assignments, true).execute
        FileDeliveryInit.prepare(report)
        FileDeliveryInit.prepare(pack)
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
      xml_piece = xml_document.at_css('piece')
      piece_name = xml_piece['name'].gsub('_', ' ')
      piece = Pack::Piece.where(name: piece_name).first
      errors = []
      errors << "Piece #{xml_piece['name']} unknown" unless piece
      errors << "Piece #{xml_piece['name']} already pre-assigned" if piece && is_already_pre_assigned?(piece)
      if errors.empty?
        [piece, xml_piece, file_path]
      else
        move_and_write_errors(file_path, errors)
        nil
      end
    end.compact
  end

  def is_already_pre_assigned?(piece)
    return true unless piece.is_awaiting_pre_assignment?
    is_a_preseizure? ? piece.preseizures.any? : piece.expense.present?
  end

  def grouped_xml_pieces
    valid_xml_pieces.group_by do |piece, xml_piece, file_path|
      piece.pack
    end
  end

  def get_pre_assignments(xml_pieces, report)
    pre_assignments = []
    xml_pieces.each do |piece, xml_piece, file_path|
      if is_abbyy_preseizure?
        pre_assignments << create_preseizure(piece, report, xml_piece)
      elsif is_preseizure?
        xml_piece.css('preseizure').each do |data|
          pre_assignments << create_preseizure(piece, report, data)
        end
      elsif is_expense?
        pre_assignments << create_expense(piece, report, xml_piece)
      end
      piece.update(is_awaiting_pre_assignment: false, pre_assignment_comment: nil)
      path = output_path.join("processed/#{Time.now.strftime("%Y-%m-%d")}")
      FileUtils.mkdir_p path
      FileUtils.mv file_path, path
      if manual_pre_assignment?
        archive_path      = manual_archive_dir.join(report.type).to_s
        file_name_pattern = manual_dir.join report.type, "#{piece.name.gsub(' ','_')}*.pdf"
        move_to_archive archive_path, file_name_pattern
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
    preseizure.piece_number     = data.at_css('piece_number').try(:content)
    preseizure.amount           = to_float(data.at_css('amount').try(:content))
    preseizure.currency         = data.at_css('currency').try(:content)
    preseizure.conversion_rate  = to_float(data.at_css('conversion_rate').try(:content))
    preseizure.third_party      = data.at_css('third_party').try(:content)
    preseizure.date             = data.at_css('date').try(:content).try(:to_date)
    preseizure.deadline_date    = data.at_css('deadline_date').try(:content).try(:to_date)
    preseizure.observation      = data.at_css('observation').try(:content)
    preseizure.position         = piece.position
    preseizure.is_made_by_abbyy = is_abbyy_preseizure?
    preseizure.save
    data.css('account').each do |xml_account|
      account = Pack::Report::Preseizure::Account.new
      account.type      = Pack::Report::Preseizure::Account.get_type(xml_account['type'])
      account.number    = xml_account['number']
      account.lettering = (is_abbyy_preseizure? ? xml_account['lettrage'] : xml_account['lettering'])
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
      if first_name.present? || last_name.present?
        g = Pack::Report::Observation::Guest.new
        g.observation = observation
        g.first_name  = first_name
        g.last_name   = last_name
        g.save
      end
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
    report.type         = journal.compta_type
    report.name         = pack.name.sub(/ all\z/, '')
    report.save
    report
  end

  def to_float(txt)
    if txt.presence
      txt.sub(',','.').to_f
    else
      nil
    end
  end

  def is_abbyy_preseizure?
    @process == 'abbyy_preseizure'
  end

  def is_preseizure?
    @process == 'preseizure'
  end

  def is_expense?
    @process == 'expense'
  end

  def is_a_preseizure?
    is_abbyy_preseizure? || is_preseizure?
  end

  def manual_pre_assignment?
    is_preseizure? || is_expense?
  end

  def output_path
    return PrepaCompta.pre_assignments_dir.join 'abbyy/output' if is_abbyy_preseizure?
    return PrepaCompta.pre_assignments_dir.join 'output/preseizures' if is_preseizure?
    PrepaCompta.pre_assignments_dir.join 'output/expenses' if is_expense?
  end

  def move_and_write_errors(file_path, errors)
    FileUtils.mkdir_p output_path.join('errors')
    FileUtils.mv file_path, output_path.join('errors')
    File.write output_path.join("errors/#{File.basename(file_path,'.xml')}.txt"), errors.join("\n")
  end

  def manual_archive_dir
    PrepaCompta.pre_assignments_dir.join 'archives'
  end

  def manual_dir
    PrepaCompta.pre_assignments_dir.join 'input'
  end

  def move_to_archive(archive_path, file_name_pattern)
    FileUtils.mkdir_p archive_path
    file_path = Dir.glob(file_name_pattern).first
    FileUtils.mv file_path, archive_path if file_path
  end

end
