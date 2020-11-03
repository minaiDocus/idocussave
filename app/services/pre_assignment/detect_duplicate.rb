class PreAssignment::DetectDuplicate
  def initialize(preseizure)
    @preseizure = preseizure
  end

  def execute
    return false unless valid? && similar_preseizure

    @preseizure.duplicate_detected_at = Time.now
    @preseizure.similar_preseizure = similar_preseizure
    @preseizure.is_blocked_for_duplication = @preseizure.organization.is_duplicate_blocker_activated
    @preseizure.save

    @preseizure.is_blocked_for_duplication ? Notifications::PreAssignments.new({preseizure: @preseizure}).notify_detected_preseizure_duplication : false
  end

  private

  def valid?
    @preseizure.third_party.present? &&
    @preseizure.cached_amount.present? &&
    @preseizure.piece_number.present?
  end

  def clean_txt(string=nil)
    string = string.to_s.strip.gsub(/[,:='"&#|;_*)}\-\]\/\\]/, ' ')
    string = string.gsub(/[!?%€$£({\[]/, '')
    string = string.gsub(/( )+/, ' ')
    string
  end

  def similar_preseizure
    return nil if @preseizure.organization.code == 'MCN'

    @similar_preseizure ||= get_match

    @piece ||= Pack::Piece.unscoped.where(id: @similar_preseizure.try(:piece_id).to_i).first

    if @piece && @piece.try(:delete_at).present?
      nil
    else
      @similar_preseizure
    end
  end

  def get_match
    preseizures = Pack::Report::Preseizure
                    .where(user_id: @preseizure.user_id, cached_amount: @preseizure.cached_amount)
                    .where.not(third_party: ['', nil], piece_number: ['', nil])
                    .where.not(id: @preseizure.id)

    matches = get_highest_match(preseizures)

    matches = get_scored_match(preseizures) if matches.empty?

    matches.try(:first)
  end

  def get_highest_match(preseizures)
    matches = []

    preseizures.each do |preseizure|
      if clean_txt(preseizure.third_party).match(/\b#{clean_txt(@preseizure.third_party)}\b/i) && clean_txt(preseizure.piece_number).match(/\b#{clean_txt(@preseizure.piece_number)}\b/i)
        matches << preseizure
      end
    end

    matches
  end

  def get_scored_match(preseizures)
    match_score = []

    third_party_words  = clean_txt(@preseizure.third_party).split(' ')
    piece_number_words = clean_txt(@preseizure.piece_number).split(' ')

    preseizures.each do |preseizure|
      tp_score = 0
      pn_score = 0

      third_party_words.each do |tp_word|
        tp_score += 1 if clean_txt(preseizure.third_party).match(/\b#{tp_word.to_s.strip}\b/i)
      end

      if tp_score > 0
        piece_number_words.each do |pn_word|
          if clean_txt(preseizure.piece_number).match(/\b#{pn_word.to_s.strip}\b/i)
            pn_score += 1
          else
            pn_score = 0
            break
          end
        end

        if pn_score > 0
          match_score << { preseizure: preseizure, score: (tp_score + pn_score) }
        end
      end
    end

    if match_score.any?
      [ match_score.sort{|a, b| b[:score] <=> a[:score]}.first[:preseizure] ]
    else
      []
    end
  end

end
