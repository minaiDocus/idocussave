# -*- encoding : UTF-8 -*-
class FecImport
  def initialize(file_path)
    @file_path = file_path
  end

  def parse_metadata
    journal_on_fec = []
    head_list_fec  = ''

    txt_file = File.read(@file_path)

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
    tab_part_account = @params[:part_account].select { |n| n != "" }

    @third_parties    = []
    @for_num_pieces   = []
    @for_pieces       = []
    @account_provider = @params[:account_provider].blank? ? 401 : @params[:account_provider].to_i
    @account_customer = @params[:account_customer].blank? ? 411 : @params[:account_customer].to_i
    @list_counter_part= tab_part_account.any? ? @params[:part_account] : ["6","7"]

    txt_file.each_line do |line|
      column      =  make_column_with line

      next if @params[:journal].nil?
      next if !@params[:journal].select{|j| j[column[0]].present? }.present?

      journal     = column[0]
      compauxnum  = column[6]
      compauxlib  = column[7]
      comptenum   = column[4]
      comptelib   = column[5]
      debit       = column[11]
      credit      = column[12]
      pieceref    = column[@params[:piece_ref].to_i]

      @third_parties  << { account_number: compauxnum, account_name: compauxlib, general_account: comptenum, journal: journal }

      @for_num_pieces << { pieceref: pieceref, compauxnum: compauxnum, journal: journal }

      @for_pieces     << { compauxnum: compauxnum, pieceref: pieceref, comptenum: comptenum, debit: debit, credit: credit, journal: journal }
    end

    @third_parties = @third_parties.uniq!.flatten[1..-1] if @third_parties.present?

    import_processing
  end

  def make_column_with(line)
    col    = line.split(/\t/)
    column = col.map { |c| c.strip }

    _account_provider = @account_provider.to_s + '00000'
    _account_customer = @account_customer.to_s + '00000'

    compaux_is_empty        = column[6].blank? && column[7].blank?
    is_provider_or_customer = [@account_provider.to_s, @account_customer.to_s].include?(column[4].to_s[0..2])
    is_general_account      = column[4].to_s.in?([_account_provider, _account_customer])

    if compaux_is_empty && is_provider_or_customer && !is_general_account
      column[6] = column[4]
      column[7] = column[5]
      column[4] = (@account_provider.to_s == column[4].to_s[0..2]) ?  _account_provider : _account_customer
      column[5] = (@account_provider.to_s == column[4].to_s[0..2]) ? 'FOURNISSEUR' : 'CLIENT'
    end

    column
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

    if @account_provider.to_i == row[:general_account].to_s[0..2].to_i
      item.kind = 'provider'
    elsif @account_customer.to_i == row[:general_account].to_s[0..2].to_i
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
      result << { journal: for_piece[:journal], ref: for_piece[:pieceref], account: for_piece[:comptenum], amount_debit: for_piece[:debit].to_f, amount_credit: for_piece[:credit].to_f } if @num_pieces.include?(for_piece[:pieceref])
    end

    @pieces = result.uniq
  end

  def parse_counterparts_and_vat_accounts
    # We select the counterpart account for a third party. We use the one with highest amounts
    @counterpart_accounts = {}
    # We do the same for VAT account
    @vat_accounts = {}

    @pieces.each do |piece|
      @counterpart_accounts[piece[:account]] = @counterpart_accounts[piece[:account]].to_i + 1 if @list_counter_part.include?(piece[:account].to_s[0]) && piece[:journal] == @third_partie[:journal]

      if %w(445).include?(piece[:account].to_s[0..2]) && piece[:journal] == @third_partie[:journal]
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