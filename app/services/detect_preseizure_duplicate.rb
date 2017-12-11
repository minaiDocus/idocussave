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
    @preseizure.amount.present? &&
    @preseizure.date.present? &&
    @preseizure.piece_number.present?
  end

  def similar_preseizure
    @similar_preseizure ||= Pack::Report::Preseizure.where(scope).where.not(id: @preseizure.id).first
  end

  def scope
    {
      user_id:      @preseizure.user_id,
      third_party:  @preseizure.third_party,
      amount:       @preseizure.amount,
      date:         @preseizure.date,
      piece_number: @preseizure.piece_number
    }
  end
end
