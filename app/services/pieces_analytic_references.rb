# -*- encoding : UTF-8 -*-
class PiecesAnalyticReferences
  def initialize(pieces=[], analytics=nil)
    @pieces = Array(pieces)
    @user   = pieces.try(:first).try(:user)
    @analytics = analytics
  end

  def update_analytics
    @errors = []
    if @pieces.any? && @user && @user.try(:uses_ibiza_analytics?)  
      analytic_validator = IbizaLib::Analytic::Validator.new(@user, @analytics)
      @errors << [:invalid_analytic_params, nil]                         unless analytic_validator.valid_analytic_presence?
      @errors << [:invalid_analytic_ventilation, nil]                    unless analytic_validator.valid_analytic_ventilation?

      if @errors.empty?
        piece_not_modified_count = IbizaLib::Analytic.add_analytic_to_pieces(analytic_validator.analytic_params_present? ? @analytics : nil, @pieces)
        piece_modified_count     = @pieces.size - piece_not_modified_count

        not_modified_piece_message  = ''
        modified_piece_message      = ''

        if piece_not_modified_count > 1
          not_modified_piece_message = "#{piece_not_modified_count} piece(s) ne sont plus modifiable (écriture(s) comptable(s) déjà livrée(s))"
        elsif piece_not_modified_count == 1
          not_modified_piece_message = "1 piece n'est plus modifiable (écriture(s) comptable(s) déjà livrée(s))"
        end

        if piece_modified_count > 1
          modified_piece_message = "Modification validée pour #{piece_modified_count} pieces"
        elsif piece_modified_count == 1
          modified_piece_message = "Modification validée pour une piece"
        end

        @pieces.each { |piece| piece.waiting_pre_assignment if piece.preseizures.empty? && piece.pre_assignment_waiting_analytics? }
      end
    else
      not_modified_piece_message = 'Aucune piece modifiable'
    end

    { error_message: full_error_messages.presence || not_modified_piece_message.presence || '', sending_message:  modified_piece_message.presence || '' }
  end

  private

  def full_error_messages
    results = []

    @errors.each do |error|
      results << I18n.t("activerecord.errors.models.uploaded_document.attributes.#{error.first}", error.last)
    end

    results.join(', ')
  end
end