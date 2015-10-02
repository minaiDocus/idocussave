# -*- encoding : UTF-8 -*-
class PrepaCompta::PreAssignPiece
  def initialize
    @schema = Nokogiri::XML::Schema(Rails.root.join('lib/xsd/pre_assignment.xsd'))
  end

  def execute
    grouped_xml_pieces.each do |pack, xml_pieces|
      period = pack.owner.subscription.find_or_create_period(Time.now)
      document = Reporting.find_or_create_period_document(pack, period)
      report = document.report || create_report(pack, document)

      preseizures = get_preseizures(xml_pieces, report)

      UpdatePeriodDataService.new(period).execute
      UpdatePeriodPriceService.new(period).execute
      if report.preseizures.not_delivered.not_locked.count > 0
        report.update_attribute(:is_delivered, false)
      end
      CreatePreAssignmentDeliveryService.new(preseizures, true).execute
      FileDeliveryInit.prepare(report)
      FileDeliveryInit.prepare(pack)
    end
  end

private

  def valid_files_path
    Dir.glob(PrepaCompta.pre_assignments_dir.join('abbyy/output/*.xml')).select do |file_path|
      File.atime(file_path) < 5.seconds.ago
    end
  end

  def valid_xml_documents
    valid_files_path.map do |file_path|
      xml_document = Nokogiri::XML(File.read(file_path))
      if @schema.validate(xml_document).map(&:to_s).empty?
        [xml_document, file_path]
      else
        FileUtils.mv file_path, PrepaCompta.pre_assignments_dir.join('abbyy/errors')
        nil
      end
    end.compact
  end

  def xml_pieces
    valid_xml_documents.map do |xml_document, file_path|
      xml_piece = xml_document.css('piece').first
      piece_name = xml_piece['name'].gsub('_', ' ')
      piece = Pack::Piece.where(name: piece_name).first
      if piece
        [piece, xml_piece, file_path]
      else
        FileUtils.mv file_path, PrepaCompta.pre_assignments_dir.join('abbyy/errors')
        nil
      end
    end.compact
  end

  def grouped_xml_pieces
    xml_pieces.group_by do |piece, xml_piece, file_path|
      piece.pack
    end
  end

  def get_preseizures(xml_pieces, report)
    xml_pieces.map do |piece, xml_piece, file_path|
      preseizure = Pack::Report::Preseizure.new
      preseizure.report           = report
      preseizure.piece            = piece
      preseizure.user             = piece.user
      preseizure.organization     = piece.user.organization
      preseizure.piece_number     = xml_piece.css('piece_number').first.try(:content)
      preseizure.amount           = to_float(xml_piece.css('amount').first.try(:content))
      preseizure.currency         = xml_piece.css('currency').first.try(:content)
      preseizure.conversion_rate  = to_float(xml_piece.css('conversion_rate').first.try(:content))
      preseizure.third_party      = xml_piece.css('third_party').first.try(:content)
      preseizure.date             = xml_piece.css('date').first.try(:content).try(:to_date)
      preseizure.deadline_date    = xml_piece.css('deadline_date').first.try(:content).try(:to_date)
      preseizure.observation      = xml_piece.css('observation').first.try(:content)
      preseizure.position         = piece.position
      preseizure.is_made_by_abbyy = true
      preseizure.save
      xml_piece.css('account').each do |xml_account|
        account = Pack::Report::Preseizure::Account.new
        account.type      = Pack::Report::Preseizure::Account.get_type(xml_account['type'])
        account.number    = xml_account['number']
        account.lettering = xml_account.css('lettering').first.try(:content)
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

      piece.update(is_awaiting_pre_assignment: false, pre_assignment_comment: nil)
      path = PrepaCompta.pre_assignments_dir.join("abbyy/processed/#{Time.now.strftime("%Y-%m-%d")}")
      FileUtils.mkdir_p path
      FileUtils.mv file_path, path
      preseizure
    end
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
end
