# -*- encoding : UTF-8 -*-
class ImportFecService
  def initialize(file_path)
    @file_path = file_path
  end

  def parse_metadata
    journal_on_fec = []
    head_list_fec  = ''

    txt_file = File.read(@file_path)
    txt_file.encode!('UTF-8')

    begin
      txt_file.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '') if txt_file.match(/\\x([0-9a-zA-Z]{2})/)
    rescue => e
      txt_file.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '')
    end

    txt_file.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '') #deletion of UTF-8 BOM

    count = 0

    txt_file.each_line do |line|
      column      = line.split(/\t/)

      head_list_fec = column if count == 0

      journal_on_fec << column[0]

      count += 1
    end

    { head_list_fec: head_list_fec, journal_on_fec: journal_on_fec.uniq!.flatten[1..-1] }
  end

  def execute(user,params)
    @user     = user
    @params   = params
    import_txt
  end

  private

  def import_csv
    #TODO : pending for example
  end

  def import_xml
    #TODO : pending for example
  end

  def import_txt
    txt_file = File.read(@file_path)
    txt_file.encode!('UTF-8')

    begin
      txt_file.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '') if txt_file.match(/\\x([0-9a-zA-Z]{2})/)
    rescue => e
      txt_file.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '')
    end

    txt_file.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '') #deletion of UTF-8 BOM

    @third_parties  = []
    @for_num_pieces = []
    @for_pieces     = []
    book_accepted   = []

    txt_file.each_line do |line|
      column      = line.split(/\t/)

      next if !@params[:journal].select{|j| j[column[0]].present? }.present?

      compauxnum  = column[6]
      compauxlib  = column[7]
      comptenum   = column[4]
      comptelib   = column[5]
      debit       = column[11]
      credit      = column[12]
      pieceref    = column[@params[:piece_ref].to_i]

      @third_parties  << { account_number: compauxnum, account_name: compauxlib, general_account: comptenum }

      @for_num_pieces << { pieceref: pieceref, compauxnum: compauxnum }

      @for_pieces     << { compauxnum: compauxnum, pieceref: pieceref, comptenum: comptenum, debit: debit, credit: credit }
    end

    @third_parties = @third_parties.uniq!.flatten[1..-1] if @third_parties.present?

    import_processing
  end

  def import_processing
    @third_parties.each do |third_partie|
      next if third_partie[:account_number].empty? && third_partie[:account_name].empty?

      #Re-Initiate variables for every loop
      @third_partie = third_partie
      @counterpart  = nil
      @vat_account  = nil

      get_num_pieces

      get_pieces_from_num_pieces

      parse_counterparts_and_vat_accounts

      next if @counterpart_accounts.empty?

      # Then update accounting plan
      update_accounting_plan_with({ aux_account: @third_partie[:account_number], aux_name: @third_partie[:account_name], counterpart_account: counterpart,  vat_account: vat_account, general_account: @third_partie[:general_account] }) if counterpart
    end
  end

  def update_accounting_plan_with(row)
    item = AccountingPlanItem.find_by_name_and_account(@user.accounting_plan.id, row[:aux_name], row[:aux_account]) || AccountingPlanItem.new

    item.third_party_account           = row[:aux_account]
    item.third_party_name              = row[:aux_name]
    item.conterpart_account            = row[:counterpart_account]
    item.code                          = row[:vat_account]
    item.accounting_plan_itemable_id   = @user.accounting_plan.id
    item.accounting_plan_itemable_type = "AccountingPlan"

    if %w(401).include?(row[:general_account].to_s[0..2])
      item.kind = 'provider'
    elsif %w(411).include?(row[:general_account].to_s[0..2])
      item.kind = 'customer'
    else
      return false
    end

    item.is_updated = true
    item.save
  end

  def get_num_pieces
    result = []

    @for_num_pieces.each do |for_num_piece|
      result << for_num_piece[:pieceref] if for_num_piece[:compauxnum] == @third_partie[:account_number]
    end

    @num_pieces = result
  end

  def get_pieces_from_num_pieces
    result = []

    @for_pieces.each do |for_piece|
      result << { ref: for_piece[:pieceref], account: for_piece[:comptenum], amount_debit: for_piece[:debit].to_f, amount_credit: for_piece[:credit].to_f } if @num_pieces.include?(for_piece[:pieceref])
    end

    @pieces = result.uniq
  end

  def parse_counterparts_and_vat_accounts
    # We select the counterpart account for a third party. We use the one with highest amounts
    @counterpart_accounts = {}
    # We do the same for VAT account
    @vat_accounts = {}

    @pieces.each do |piece|
      @counterpart_accounts[piece[:account]] = @counterpart_accounts[piece[:account]].to_i + 1 if %w(6 7).include?(piece[:account].to_s[0])

      if %w(445).include?(piece[:account].to_s[0..2])
        amount = piece[:amount_debit] > 0 ? piece[:amount_debit] : piece[:amount_credit]
        @vat_accounts[piece[:account]] = @vat_accounts[piece[:account]].to_f + amount
      end
    end
  end

  def counterpart
    return @counterpart if @counterpart

    result = @counterpart_accounts.max_by{|k,v| v}
    @counterpart = result.first if result
  end

  def vat_account
    return @vat_account if @vat_account

    result = @vat_accounts.max_by{|k,v| v}
    @vat_account = result.first if result
  end
end