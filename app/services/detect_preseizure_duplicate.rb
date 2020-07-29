class DetectPreseizureDuplicate
  def initialize(preseizure)
    @preseizure = preseizure
  end

  def execute
    return false unless valid? && similar_preseizure

    @preseizure.duplicate_detected_at = Time.now
    @preseizure.similar_preseizure = similar_preseizure
    @preseizure.is_blocked_for_duplication = @preseizure.organization.is_duplicate_blocker_activated
    @preseizure.save

    @preseizure.is_blocked_for_duplication ? NotifyDetectedPreseizureDuplicate.new(@preseizure, 5.minutes).execute : false
  end

  private

  def valid?
    @preseizure.third_party.present? &&
    @preseizure.cached_amount.present? &&
    @preseizure.piece_number.present?
  end

  def similar_preseizure
    return nil if @preseizure.organization.code == 'MCN'

    @similar_preseizure ||= Pack::Report::Preseizure.where(scope).where.not(id: @preseizure.id).first

    @piece ||= Pack::Piece.unscoped.where(id: @similar_preseizure.try(:piece_id).to_i).first

    if @piece && @piece.try(:delete_at).present?
      nil
    else
      @similar_preseizure
    end
  end

  def scope
    {
      user_id:       @preseizure.user_id,
      third_party:   @preseizure.third_party,
      cached_amount: @preseizure.cached_amount,
      piece_number:  @preseizure.piece_number
    }
  end
end
