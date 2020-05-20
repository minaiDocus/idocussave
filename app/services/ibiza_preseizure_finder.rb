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
    return false

    # client.request.clear

    # if preseizure.piece
    #   search_term = preseizure.piece_number
    #   search_query_A = 'piece'
    #   search_query_B = 'voucherRef'
    # else
    #   search_term = preseizure.operation_name
    #   search_query_A ='voucherRef'
    #   search_query_B ='piece'
    # end

    # return false if search_term.to_s.size <= 6

    # voucher_ref_target = ibiza.try(:voucher_ref_target).presence || 'piece_number'
    # case voucher_ref_target
    #   when 'piece_name'
    #     client.company(user.ibiza_id).grandlivregeneral?("q=#{search_query_A}='#{search_term}'")
    #   else
    #     client.company(user.ibiza_id).grandlivregeneral?("q=#{search_query_B}='#{search_term}'")
    # end

    # if client.response.success?
    #   response = Nokogiri::XML client.response.body.force_encoding('UTF-8')
    #   response.at_css('data').children.presence ?  true : false
    # else
    #   false
    # end
  end

  private

  def client
    ibiza.client
  end

end