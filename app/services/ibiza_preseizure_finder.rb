# -*- encoding : UTF-8 -*-
class IbizaPreseizureFinder
  attr_accessor :user, :ibiza

  def initialize(preseizures)
    @preseizures = Array(preseizures)
    @user        = @preseizures.first.user
    @ibiza       = @user.organization.try(:ibiza)
  end

  def self.not_delivered(preseizures)
    new(preseizures).not_delivered
  end

  def self.is_delivered?(preseizures)
    not_delivered(preseizures).empty?
  end

  def not_delivered
    return [] unless valid?
    @preseizures.select { |preseizure| !is_delivered?(preseizure) }
  end

  def valid?
    ibiza.try(:configured?) && user.try(:ibiza_id).present?
  end

  def is_delivered?(preseizure)
    client.request.clear

    account     = preseizure.accounts.first
    third_party = account.number

    entry  = account.entries.first
    amount = entry.amount

    if entry.type == Pack::Report::Preseizure::Entry::DEBIT
      entry_type = 'debit'
    else
      entry_type = 'credit'
    end

    if preseizure.piece
      if preseizure.piece_number.present?
        search_term = preseizure.piece_number
        search_query_A = 'piece'
        search_query_B = 'voucherRef'
      else
        search_term = IbizaAPI::Utils.piece_name(preseizure.piece.name, ibiza.piece_name_format , ibiza.piece_name_format_sep)
        search_query_A = 'voucherRef'
        search_query_B = 'piece'
      end
    else
      search_term = preseizure.operation_name
      search_query_A ='voucherRef'
      search_query_B ='piece'
    end

    voucher_ref_target = ibiza.try(:voucher_ref_target).presence || 'piece_number'
    case voucher_ref_target
      when 'piece_name'
        client.company(user.ibiza_id).grandlivregeneral?("q=#{search_query_A}='#{search_term.to_s.gsub(/[\[\]()=&!]/, '')}' and number='#{third_party.to_s.gsub(/[\[\]()=&!]/, '')}' and #{entry_type}='#{amount}'")
      else
        client.company(user.ibiza_id).grandlivregeneral?("q=#{search_query_B}='#{search_term.to_s.gsub(/[\[\]()=&!]/, '')}' and number='#{third_party.to_s.gsub(/[\[\]()=&!]/, '')}' and #{entry_type}='#{amount}'")
    end

    if client.response.success?
      response = Nokogiri::XML client.response.body.force_encoding('UTF-8')
      response.at_css('data').children.presence ?  true : false
    else
      false
    end
  end

  private

  def client
    ibiza.client
  end

end