class Pack::Report::Preseizure < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :user,                                  inverse_of: :preseizures
  belongs_to :piece,     class_name: 'Pack::Piece',  inverse_of: :preseizures, optional: true
  belongs_to :report,    class_name: 'Pack::Report', inverse_of: :preseizures
  belongs_to :operation, class_name: 'Operation',    inverse_of: :preseizure, optional: true
  belongs_to :organization,                          inverse_of: :preseizures
  has_one    :analytic_reference, through: :piece

  has_many :entries,  class_name: 'Pack::Report::Preseizure::Entry',   inverse_of: :preseizure, dependent: :destroy
  has_many :accounts, class_name: 'Pack::Report::Preseizure::Account', inverse_of: :preseizure, dependent: :destroy

  has_and_belongs_to_many :remote_files, foreign_key: 'pack_report_preseizure_id'
  has_and_belongs_to_many :pre_assignment_deliveries
  has_and_belongs_to_many :pre_assignment_exports

  has_many :duplicates, class_name: 'Pack::Report::Preseizure', foreign_key: :similar_preseizure_id
  belongs_to :similar_preseizure, class_name: 'Pack::Report::Preseizure', optional: true

  scope :locked,                        -> { where(is_locked: true) }
  scope :failed_delivery,               -> { where(is_delivered_to: [nil, '']).where.not(delivery_message: [nil, '', '{}']).where.not(delivery_tried_at: nil) }
  scope :not_locked,                    -> { where(is_locked: false) }
  scope :by_position,                   -> { order(position: :asc) }
  scope :not_deleted,                   -> { joins('LEFT JOIN pack_pieces ON pack_report_preseizures.piece_id = pack_pieces.id').where('pack_pieces.id IS NULL OR pack_pieces.delete_at is NULL') }
  scope :exported,                      -> { joins('INNER JOIN pack_report_preseizures_pre_assignment_exports ON pack_report_preseizures.id = pack_report_preseizures_pre_assignment_exports.preseizure_id').where('pack_report_preseizures_pre_assignment_exports.id > 0').distinct }
  scope :not_exported,                  -> { joins('LEFT JOIN pack_report_preseizures_pre_assignment_exports ON pack_report_preseizures.id = pack_report_preseizures_pre_assignment_exports.preseizure_id').where('pack_report_preseizures_pre_assignment_exports.id IS NULL').distinct }


  scope :blocked_duplicates,            -> { where(is_blocked_for_duplication: true, marked_as_duplicate_at: nil) }
  scope :potential_duplicates,          -> { where.not(duplicate_detected_at: nil) }
  scope :approved_duplicates,           -> { where.not(marked_as_duplicate_at: nil) }
  scope :disapproved_duplicates,        -> { where.not(duplicate_unblocked_at: nil) }

  default_scope { where(is_blocked_for_duplication: false) }

  def self.search(contains)
    preseizures = self.all
    preseizures = preseizures.joins(:organization, :piece, :user)
    preseizures = preseizures.where("organizations.name LIKE ?", "%#{contains[:organization_name]}%") if contains[:organization_name].present?
    preseizures = preseizures.where("pack_pieces.name LIKE ?", "%#{contains[:piece_name]}%") if contains[:piece_name].present?
    preseizures = preseizures.where("piece_number LIKE ?", "%#{contains[:piece_number]}%") if contains[:piece_number].present?
    preseizures = preseizures.where("third_party LIKE ?", "%#{contains[:third_party]}%") if contains[:third_party].present?
    preseizures = preseizures.where("users.company LIKE ?", "%#{contains[:company]}%") if contains[:company].present?
    preseizures = preseizures.where(cached_amount: contains[:amount]) if contains[:amount].present?

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        preseizures = preseizures.where("pack_report_preseizures.created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    if contains[:date]
      contains[:date].each do |operator, value|
        preseizures = preseizures.where("date #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    preseizures.distinct
  end

  def self.filter_by(options)
    preseizures = self.all

    return preseizures unless options.present?

    preseizures = preseizures.delivered           if options[:is_delivered].present? && options[:is_delivered].to_i == 1
    preseizures = preseizures.not_delivered       if options[:is_delivered].present? && options[:is_delivered].to_i == 2
    preseizures = preseizures.failed_delivery     if options[:is_delivered].present? && options[:is_delivered].to_i == 3
    preseizures = preseizures.exported            if options[:is_delivered].present? && options[:is_delivered].to_i == 4
    preseizures = preseizures.not_exported        if options[:is_delivered].present? && options[:is_delivered].to_i == 5

    preseizures = preseizures.where("DATE_FORMAT(pack_report_preseizures.created_at, '%Y-%m-%d') #{options[:created_at_operation].tr('012', ' ><')}= ?", options[:created_at])                        if options[:created_at].present?
    preseizures = preseizures.where("DATE_FORMAT(pack_report_preseizures.date, '%Y-%m-%d') #{options[:date_operation].tr('012', ' ><')}= ?", options[:date])                                          if options[:date].present?
    preseizures = preseizures.where("DATE_FORMAT(pack_report_preseizures.delivery_tried_at, '%Y-%m-%d') #{options[:delivery_tried_at_operation].tr('012', ' ><')}= ?", options[:delivery_tried_at])   if options[:delivery_tried_at].present?
    preseizures = preseizures.where("pack_report_preseizures.cached_amount #{options[:amount_operation].tr('012', ' ><')}= ?", options[:amount])                                                      if options[:amount].present?
    preseizures = preseizures.where("pack_report_preseizures.position #{options[:position_operation].tr('012', ' ><')}= ?", options[:position])                                                       if options[:position].present?

    preseizures = preseizures.where(piece_number: options[:piece_number]) if options[:piece_number].present?
    preseizures = preseizures.where('pack_report_preseizures.third_party LIKE ?', "%#{options[:third_party]}%") if options[:third_party].present?

    preseizures.distinct
  end

  def self.not_delivered(software=nil)
    preseizures = self.all

    if software.nil?
      user_ids = []

      ['ibiza', 'my_unisoft', 'exact_online'].each do |software_name|
        model_software = Interfaces::Software::Configuration.softwares[software_name.to_sym]
        user_ids = user_ids + model_software.where(is_used: true, owner_type: 'User').pluck(:owner_id)
      end

      user_ids = user_ids.flatten.compact.uniq

      preseizures = preseizures.where(user_id: user_ids).where(is_delivered_to: [nil, ''])
    else
      return preseizures.where(id: -1) if not software.in? Interfaces::Software::Configuration::SOFTWARES #IMPORTANT : we return an empty active record not an Array

      model_software = Interfaces::Software::Configuration.softwares[software.to_sym]

      user_ids = model_software.where(is_used: true, owner_type: 'User').pluck(:owner_id)

      preseizures = preseizures.where(user_id: user_ids).where.not(is_delivered_to: software)
    end

    preseizures.distinct
  end

  def self.delivered(software=nil)
    preseizures = self.all

    if software.nil?
      preseizures = preseizures.where.not(is_delivered_to: [nil, ''])
    else
      preseizures = preseizures.where("is_delivered_to = '#{software}'")
    end

    preseizures
  end

  #Override belong_to piece getter because of default scope
  def piece
    Pack::Piece.unscoped.where(id: self.piece_id).first || nil
  end

  def piece_name
    piece.try(:name) || report.name
  end

  def coala_piece_name
    journal_name + report.name.split(' ')[-1][2..-1] + '%03d' % position
  end

  def operation_name
    report.name + ' %03d' % position
  end

  def piece_content_url
    return nil unless piece
    piece.cloud_content_object.try(:url) if piece
  end

  def journal_name
    if self.operation
      operation.bank_account.try(:foreign_journal).presence || operation.bank_account.try(:journal) || report.journal
    else
      report.journal
    end
  end

  # type may only be pseudonym or name
  def journal_prefered_name(type = :pseudonym)
    journal = report.journal({ name_only: false })

    begin
      if self.operation
        operation.bank_account.try(:foreign_journal).presence || operation.bank_account.try(:journal) || journal.send(type.to_sym).to_s
      else
        journal.send(type.to_sym).to_s
      end
    rescue
      ''
    end
  end

  def period_date
    Time.local(year, month, 1)
  end


  def end_period_date
    if quarterly?
      period_date + 3.months
    elsif annually?
      period_date + 12.months
    else
      period_date.end_of_month
    end
  end

  def computed_date(exercise=nil)
    date = self.date.try(:to_date)

    return date if self.operation

    if self.is_period_range_used
      out_of_period_range = begin
                              date < self.period_start_date || self.period_end_date < date
                            rescue
                              true
                            end
    end

    result = if (self.is_period_range_used && out_of_period_range) || date.nil?
               self.period_start_date
             else
               date
             end

    if exercise
      if result < exercise.start_date && result.beginning_of_month == exercise.start_date.beginning_of_month
        exercise.start_date
      elsif exercise.next.nil? && result > exercise.end_date && result.beginning_of_month == exercise.end_date.beginning_of_month
        exercise.end_date
      else
        result
      end
    else
      result
    end
  end

  def computed_deadline_date(exercise=nil)
    return nil unless self.deadline_date.present?

    date = computed_date exercise
    result = self.deadline_date < date ? date : self.deadline_date
    result.to_date
  end

  def period_start_date
    period_date.to_date
  end


  def period_end_date
    end_period_date.to_date
  end


  def is_period_range_used
    report.user.options.pre_assignment_date_computed?
  end


  def piece_info
    piece_name.split(' ')
  end


  def syear
    piece_info[2][0..3]
  end


  def year
    syear.to_i
  end


  def smonth
    piece_info[2][4..5]
  end


  def month
    if annually?
      1
    elsif quarterly?
      (smonth[1].to_i * 3) - 2
    else
      smonth.to_i
    end
  end


  def annually?
    piece_info[2].size == 4
  end


  def quarterly?
    smonth[0] == 'T'
  end


  def amount_in_cents
    (amount * 100).round
  rescue
    nil
  end

  def is_delivered?
    ( self.user.try(:uses?, :ibiza) && is_delivered_to?('ibiza') ) ||
    ( self.user.try(:uses?, :exact_online) && is_delivered_to?('exact_online') )
  end

  def is_not_delivered?
    ( self.user.try(:uses?, :ibiza) && !is_delivered_to?('ibiza') ) ||
    ( self.user.try(:uses?, :exact_online) && !is_delivered_to?('exact_online') )
  end

  def is_exported?
    pre_assignment_exports.count > 0
  end

  def delivery_failed?
    is_not_delivered? && delivery_message != '' && delivery_message != '{}'
  end

  def is_not_blocked_for_duplication
    !is_blocked_for_duplication
  end

  def duplicate_unblocked_by_user
    @duplicate_unblocked_by_user ||= User.find_by id: duplicate_unblocked_by_user_id
  end

  def marked_as_duplicate_by_user
    @marked_as_duplicate_by_user ||= User.find_by id: marked_as_duplicate_by_user_id
  end

  def has_deleted_piece?
    self.piece.try(:delete_at).try(:present?) ? true : false
  end

  def delivered_to(software)
    return true if is_delivered_to?(software)

    # softwares = self.is_delivered_to.split(',') || []
    # softwares << software
    # self.is_delivered_to = softwares.sort.join(',')
    self.is_delivered_to = software
    save
  end

  def is_delivered_to?(software='ibiza')
    self.is_delivered_to.to_s.match(/#{software}/) ? true : false
  end

  def set_delivery_message_for(software='ibiza', message)
    begin
      mess = self.delivery_message.present? ? JSON.parse(self.delivery_message) : {}
    rescue
      mess = {}
    end

    if message.present?
      mess[software.to_s] = message
    else
      mess.except!(software.to_s)
    end
    self.delivery_message = mess.to_json.to_s
    save
  end

  def get_delivery_message_of(software='ibiza')
    mess = ''
    if self.delivery_message.present?
      mess = JSON.parse(self.delivery_message) rescue { "#{software.to_s}" => self.delivery_message }
      mess = mess[software.to_s] || ''
    end
    mess
  end

  def update_entries_amount
    if self.conversion_rate.present? && self.conversion_rate > 0 && self.amount.present? && self.amount > 0
      self.cached_amount = (self.amount / self.conversion_rate).round(2)

      self.accounts.each do |account|
        if account.type == Pack::Report::Preseizure::Account::TTC || account.type == Pack::Report::Preseizure::Account::HT
          account.entries.first.update(amount: self.cached_amount)
        elsif account.type == Pack::Report::Preseizure::Account::TVA
          account.entries.first.update(amount: 0)
        end
      end

      save
    end
  end

  def get_state_to(type='image')
    text    = 'none'
    img_url = ''

    if is_delivered?
      text    = 'delivered'
      img_url = 'application/preaff_deliv.png'
    elsif is_not_delivered? && !self.delivery_tried_at.present?
      text    = 'delivery_pending'
      img_url = 'application/preaff_deliv_pending.png'
    elsif is_not_delivered? && self.delivery_tried_at.present? && self.delivery_message.present? && self.delivery_message != '{}'
      text    = 'delivery_failed'
      img_url = 'application/preaff_err.png'
    end

    return text if type.to_s == 'text'
    return img_url
  end
end
