# -*- encoding : UTF-8 -*-
class ImportFecService
	def initialize(file_path)
		@file_path = file_path
	end

	def execute(user,is_coala=false)
		@user     = user
    @is_coala = is_coala
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
		@for_pieces 		= []

		txt_file.each_line do |line|
			column 		  = line.split(/\t/)

			compauxnum  = column[6]
			compauxlib  = column[7]
			comptenum   = column[4]
			comptelib   = column[5]
			debit		    = column[11]
			credit		  = column[12]
			pieceref 	  = @is_coala ? column[2] : column[8]

			@third_parties  << { account_number: compauxnum, account_name: compauxlib, general_account: comptenum }

			@for_num_pieces << { pieceref: pieceref, compauxnum: compauxnum }

			@for_pieces     << { compauxnum: compauxnum, pieceref: pieceref, comptenum: comptenum, debit: debit, credit: credit }

		end

		@third_parties   = @third_parties.uniq!.flatten[1..-1]

		import_processing
	end

	def import_processing

		accounting_plan = []

		@third_parties.each do |third_partie|

      next if third_partie[:account_number].empty? && third_partie[:account_name].empty?

			# We create an array of pieces identifiers
		  num_pieces = []

		  @for_num_pieces.each do |for_num_piece|
				num_pieces << for_num_piece[:pieceref] if for_num_piece[:compauxnum] == third_partie[:account_number]
		  end

		  pieces = []


		  @for_pieces.each do |for_piece|
				pieces << { ref: for_piece[:pieceref], account: for_piece[:comptenum], amount_debit: for_piece[:debit].to_f, amount_credit: for_piece[:credit].to_f } if num_pieces.include?(for_piece[:pieceref])
		  end

		  pieces.uniq!

		  # We then select the counterpart account for a third party. We use the one with highest amounts
		  counterpart_accounts = {}
		  # We then do the same for VAT account
		  vat_accounts = {}

		  pieces.each do |piece|
        counterpart_accounts[piece[:account]] = counterpart_accounts[piece[:account]].to_i + 1 if %w(6 7).include?(piece[:account].to_s[0])

        if %w(445).include?(piece[:account].to_s[0..2])
          amount = piece[:amount_debit] > 0 ? piece[:amount_debit] : piece[:amount_credit]
		  	  vat_accounts[piece[:account]] = 0 
		  	  vat_accounts[piece[:account]] += amount
        end

		  end

      next if counterpart_accounts.empty?

		  counterpart = counterpart_accounts.max_by{|k,v| v}

		  counterpart = counterpart.first if counterpart

		  vat_account = vat_accounts.max_by{|k,v| v}

		  vat_account = vat_account.first if vat_account

		  # Then update the accounting plan
	 		accounting_plan << { aux_account: third_partie[:account_number], aux_name: third_partie[:account_name], counterpart_account: counterpart,  vat_account: vat_account, general_account: third_partie[:general_account] } if counterpart
		end

		accounting_plan.each do |row|

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
        next
      end

      item.is_updated = true
      item.save
    end
	end
end