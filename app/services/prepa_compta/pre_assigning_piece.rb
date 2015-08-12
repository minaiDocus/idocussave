# -*- encoding : UTF-8 -*-
class PrepaCompta::PreAssigningPiece
  class << self
    def execute(pieces)
      pieces.each do |piece|
        new(piece).execute unless piece.is_a_cover
      end
    end
  end

  def initialize(piece)
    @piece = piece
  end

  def execute
    copy_to_dir manual_dir
    copy_to_dir abbyy_dir unless journal.compta_type == 'NDF'
    @piece.update(is_awaiting_pre_assignment: true)
  end

private

  def file_name
    if @file_name
      @file_name
    else
      data = [@piece.name]
      if journal.is_pre_assignment_processable?
        data << "DTI#{journal.default_account_number}"
        data << "ATI#{journal.account_number}"
        data << "DCP#{journal.default_charge_account}"
        data << "ACP#{journal.charge_account}"
        data << "TVA#{journal.vat_account}"
        data << "ANO#{journal.anomaly_account}"
        data << "TAX#{is_taxable ? 1 : 0}"
      end
      @file_name = data.join('_').gsub(/\/+/, '').gsub(' ', '_') + '.pdf'
    end
  end

  def manual_dir
    list = PrepaCompta.pre_assignments_dir
    list = list.join('input', Time.now.strftime('%Y-%m-%d'))
    list = list.join('dynamic') if @piece.temp_document.is_an_original
    list.join(journal.compta_type)
  end

  def abbyy_dir
    PrepaCompta.pre_assignments_dir.join 'abbyy', 'input', journal.compta_type
  end

  def journal
    @journal ||= @piece.user.account_book_types.where(name: @piece.journal).first
  end

  def is_taxable
    @is_taxable ||= @piece.user.options.is_taxable
  end

  def copy_to_dir(dir)
    FileUtils.mkdir_p(dir)
    FileUtils.cp(@piece.content.path, File.join(dir, file_name))
  end
end
