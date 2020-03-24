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
    piece_name = if preseizure.piece
      IbizaAPI::Utils.piece_name(preseizure.piece.name, ibiza.piece_name_format , ibiza.piece_name_format_sep)
    else
      preseizure.operation_name
    end

    client.company(user.ibiza_id).grandlivregeneral?(URI.escape("q=piece='#{piece_name}'"))

    if client.response.success?
      response = Nokogiri::XML client.response.body.force_encoding('UTF-8')
      response.at_css('data').children.presence ?  true : false
    else
      true
    end
  end

  private

  def client
    ibiza.client
  end

end