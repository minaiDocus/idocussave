class AdvancedPreseizure < ActiveRecord::Base
  DELIVERY_STATE = { delivered: 1, not_delivered: 2, failed: 3 }

  scope :delivered,                     -> { where(delivery_state: 'delivered') }
  scope :not_delivered,                 -> { where(delivery_state: 'not_delivered') }
  scope :not_delivered_and_failed,      -> { where(delivery_state: ['not_delivered', 'failed']) }
  scope :failed_delivery,               -> { where(delivery_state: 'failed') }

  def self.search(fetch='preseizures', options={}, related_to=nil)
    case fetch
      when 'preseizures'
        field_select = 'id'
        object = Pack::Report::Preseizure
      when 'packs'
        field_select = 'pack_id'
        object = Pack
      when 'reports'
        field_select = 'report_id'
        object = Pack::Report
      when 'pieces'
        field_select = 'piece_id'
        object = Pack::Piece
    end

    if(options.present?)
      collections = self.all

      collections = prepare_relation_of collections, related_to

      collections = collections.where(user_id: options[:user_ids]) if options[:user_ids].present?

      collections = collections.where(piece_number: options[:piece_number])  if options[:piece_number].present?
      collections = collections.where('advanced_preseizures.third_party LIKE ?', "%#{options[:third_party]}%")  if options[:third_party].present?

      collections = collections.delivered                 if options[:is_delivered].present? && options[:is_delivered].to_i == AdvancedPreseizure::DELIVERY_STATE[:delivered]
      collections = collections.not_delivered_and_failed  if options[:is_delivered].present? && options[:is_delivered].to_i == AdvancedPreseizure::DELIVERY_STATE[:not_delivered]
      collections = collections.failed_delivery           if options[:is_delivered].present? && options[:is_delivered].to_i == AdvancedPreseizure::DELIVERY_STATE[:failed]

      collections = collections.where("DATE_FORMAT(advanced_preseizures.date, '%Y-%m-%d') #{options[:date_operation].tr('012', ' ><')}= ?", options[:date_at]) if options[:date].present?
      collections = collections.where("DATE_FORMAT(advanced_preseizures.delivery_tried_at, '%Y-%m-%d') #{options[:delivery_tried_at_operation].tr('012', ' ><')}= ?", options[:delivery_tried_at]) if options[:delivery_tried_at].present?
      collections = collections.where("advanced_preseizures.cached_amount #{options[:amount_operation].tr('012', ' ><')}= ?", options[:amount]) if options[:amount].present?
      collections = collections.where("advanced_preseizures.position #{options[:position_operation].tr('012', ' ><')}= ?", options[:position])  if options[:position].present?

      ids = collections.distinct.pluck(field_select).presence || [0]

      object = object.where("#{object.table_name}.id IN (#{ids.join(',')})")
    else
      object = related_to
    end

    object
  end

  private

  def self.prepare_relation_of(relation=nil, related_to=nil)
    return relation if related_to.nil?

    if related_to.class == Pack::ActiveRecord_Relation
      ids = related_to.pluck('packs.id').presence || [0]
      relation_id = 'pack_id'
    elsif related_to.class == Pack::Report::ActiveRecord_Relation
      ids = related_to.pluck('pack_reports.id').presence || [0]
      relation_id = 'report_id'
    elsif related_to.class == Pack::Piece::ActiveRecord_Relation
      ids = related_to.pluck('pack_pieces.id').presence || [0]
      relation_id = 'piece_id'
    elsif related_to.class == User::ActiveRecord_Relation
      ids = related_to.pluck('users.id').presence || [0]
      relation_id = 'user_id'
    elsif related_to.class == Pack
      ids = [related_to.id]
      relation_id = 'pack_id'
    elsif related_to.class == Pack::Report
      ids = [related_to.id]
      relation_id = 'report_id'
    elsif related_to.class == Pack::Piece
      ids = [related_to.id]
      relation_id = 'piece_id'
    elsif related_to.class == User
      ids = [related_to.id]
      relation_id = 'user_id'
    end

    relation = relation.where("advanced_preseizures.#{relation_id} IN (#{ids.join(',')})")
    relation
  end

end