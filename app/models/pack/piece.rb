# -*- encoding : UTF-8 -*-
class Pack::Piece < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/account/documents/pieces/:id/download/:style'}

  serialize :tags

  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan retriever)

  before_validation :set_number

  has_one    :expense, class_name: 'Pack::Report::Expense', inverse_of: :piece
  has_one    :temp_document, inverse_of: :piece

  has_many   :operations,    class_name: 'Operation', inverse_of: :piece
  has_many   :preseizures,   class_name: 'Pack::Report::Preseizure', inverse_of: :piece
  has_many   :temp_preseizures,  class_name: 'Pack::Report::TempPreseizure', inverse_of: :piece
  has_many   :remote_files,  as: :remotable, dependent: :destroy

  belongs_to :user
  belongs_to :pack, inverse_of: :pieces
  belongs_to :organization
  belongs_to :analytic_reference, inverse_of: :pieces, optional: true

  has_one_attached :cloud_content
  has_one_attached :cloud_content_thumbnail

  has_attached_file :content, styles: { medium: ['92x133', :png] },
                              path: ':rails_root/files/:rails_env/:class/:attachment/:mongo_id_or_id/:style/:filename',
                              url: '/account/documents/pieces/:id/download/:style'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  after_create_commit do |piece|
    unless Rails.env.test?
      Pack::Piece.delay_for(10.seconds, queue: :low).finalize_piece(piece.id)
    end
  end

  before_destroy do |piece|
    piece.cloud_content.purge

    current_analytic = piece.analytic_reference
    current_analytic.destroy if current_analytic && !current_analytic.is_used_by_other_than?({ pieces: [piece.id] })
  end

  scope :covers,                 -> { where(is_a_cover: true) }
  scope :scanned,                -> { where(origin: 'scan') }
  scope :retrieved,              -> { where(origin: 'retriever') }
  scope :of_month,               -> (time) { where('created_at > ? AND created_at < ?', time.beginning_of_month, time.end_of_month) }
  scope :uploaded,               -> { where(origin: 'upload') }
  scope :not_covers,             -> { where(is_a_cover: [false, nil]) }
  scope :by_position,            -> { order(position: :asc) }
  scope :dematbox_scanned,       -> { where(origin: 'dematbox_scan') }
  scope :pre_assignment_ignored, -> { where(pre_assignment_state: ['ignored', 'force_processing']) }
  scope :deleted,                -> { where.not(delete_at: nil) }

  #WORKARROUND : Get pieces with suplier_recognition state and detected_third_party_id present
  # scope :need_preassignment,   -> { where(pre_assignment_state: 'waiting') }
  scope :need_preassignment,     -> { where("DATE_FORMAT(created_at, '%Y%m%d') >= #{3.months.ago.strftime('%Y%m%d')}").where('(pre_assignment_state = "waiting" OR pre_assignment_state = "force_processing" OR (pre_assignment_state = "supplier_recognition" && detected_third_party_id > 0))') }
  scope :awaiting_preassignment, -> { where('pre_assignment_state = "waiting" OR pre_assignment_state = "force_processing"') }

  scope :pre_assignment_supplier_recognition, -> { where(pre_assignment_state: ['supplier_recognition']) }

  default_scope { where(delete_at: [nil, '']) }

  scope :of_period, lambda { |time, duration|
    case duration
    when 1
      start_at = time.beginning_of_month
      end_at   = time.end_of_month
    when 3
      start_at = time.beginning_of_quarter
      end_at   = time.end_of_quarter
    when 12
      start_at = time.beginning_of_year
      end_at   = time.end_of_year
    end
    where('created_at >= ? AND created_at <= ?', start_at, end_at)
  }

  state_machine :pre_assignment_state, initial: :ready, namespace: :pre_assignment do
    state :ready
    state :waiting
    state :supplier_recognition
    state :waiting_analytics
    state :force_processing
    state :processed
    state :ignored
    state :truly_ignored
    state :not_processed

    event :ready do
      transition any => :ready
    end

    event :waiting do
      transition [:supplier_recognition, :ready, :waiting_analytics] => :waiting
    end

    event :recognize_supplier do
      transition :ready => :supplier_recognition
    end

    event :waiting_analytics do
      transition :ready => :waiting_analytics
    end

    event :force_processing do
      transition [:ready, :waiting, :waiting_analytics, :ignored] => :force_processing
    end

    event :processed do
      transition [:waiting, :force_processing] => :processed
    end

    event :ignored do
      transition waiting: :ignored
    end

    event :confirm_ignorance do
      transition ignored: :truly_ignored
    end

    event :not_processed do
      transition [:waiting, :force_processing] => :not_processed
    end
  end

  def self.search(text, options = {})
    page = options[:page] || 1
    per_page = options[:per_page] || default_per_page

    query = self.joins(:pack)

    query = query.where(id: options[:id])                                                        if options[:id].present?
    query = query.where(id: options[:ids])                                                       if options[:ids].present?
    query = query.where('packs.id = ?', options[:pack_id] )                                      if options[:pack_id].present?
    query = query.where('packs.id IN (?)', options[:pack_ids])                                   if options[:pack_ids].present?
    query = query.where('packs.name LIKE ?', "%#{options[:pack_name]}%")                         if options[:pack_name].present?
    query = query.where('pack_pieces.name LIKE ?', "%#{options[:piece_name]}%")                  if options[:piece_name].present?
    query = query.where('pack_pieces.number LIKE ?', "%#{options[:piece_number]}%")              if options[:piece_number].present?
    query = query.where('pack_pieces.pre_assignment_state = ?', options[:pre_assignment_state])  if options[:pre_assignment_state].present?

    if options[:created_at]
      options[:created_at].each do |operator, value|
        query = query.where("pack_pieces.created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    query = query.where('pack_pieces.name LIKE ? OR pack_pieces.tags LIKE ? OR pack_pieces.content_text LIKE ?', "%#{text}%", "%#{text}%", "%#{text}%") if text.present?

    query.order(position: :asc) if options[:sort] == true

    query.page(page).per(per_page)
  end

  def self.finalize_piece(id)
    piece = Pack::Piece.find(id)

    unless piece.tags.present?
      piece.init_tags
      piece.save
    end

    return true if piece.is_finalized

    piece.is_finalized = true
    self.extract_content(piece) unless piece.content_text.present?
    self.generate_thumbs(piece.id)

    piece.save
  end

  def self.generate_thumbs(id)
    piece = Pack::Piece.find(id)

    base_file_name = piece.cloud_content_object.filename.to_s.gsub('.pdf', '')

    begin
      image = MiniMagick::Image.read(piece.cloud_content.download).format('png').resize('92x133')

      piece.cloud_content_thumbnail.attach(io: File.open(image.tempfile),
                                           filename: "#{base_file_name}.png",
                                           content_type: "image/png")
    rescue
      piece.is_finalized = false
    end

    piece.save
  end

  def self.extract_content(piece)
    begin
      path = piece.cloud_content_object.path

      POSIX::Spawn.system "pdftotext -raw -nopgbrk -q #{path}"

      dirname  = File.dirname(path)
      filename = File.basename(path, '.pdf') + '.txt'
      filepath = File.join(dirname, filename)

      if File.exist?(filepath)
        text = File.open(filepath, 'r').readlines.map(&:strip).join(' ')
        # remove special character, which will not be used on search anyway
        text = text.each_char.select { |c| c.bytes.size < 4 }.join
        piece.content_text = text
      end

      piece.content_text = ' ' unless piece.content_text.present?

      piece.save
    rescue => e
      piece.is_finalized = false
    end
  end

  def self.correct_pdf_signature_of(piece_id)
    piece = Pack::Piece.find piece_id
    piece.correct_pdf_signature
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def recreate_pdf(temp_dir = nil)
    unless temp_document
      log_document = {
        subject: "[Pack::Piece] piece without temp document recreate pdf",
        name: "Pack::Piece",
        error_group: "[pack-piece] piece without temp_document recreate_pdf",
        erreur_type: "Piece without temp_document - recreate_pdf",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          model: self.inspect,
          user: self.user.inspect,
          method: "recreate_pdf"
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver

      return false
    end

    piece_file_path = ''

    CustomUtils.mktmpdir('piece', temp_dir, !temp_dir.present?) do |dir|
      piece_file_name = DocumentTools.file_name self.name
      piece_file_path = File.join(dir, piece_file_name)

      original_file_path = File.join(dir, 'original.pdf')

      FileUtils.cp temp_document.cloud_content_object.path, original_file_path
      DocumentTools.correct_pdf_if_needed original_file_path

      DocumentTools.create_stamped_file original_file_path, piece_file_path, user.stamp_name, self.name, {origin: temp_document.delivery_type, is_stamp_background_filled: user.is_stamp_background_filled, dir: dir}
      self.cloud_content_object.attach(File.open(piece_file_path), piece_file_name)

      self.try(:sign_piece)

      self.get_pages_number
    end

    piece_file_path
  end

  def correct_pdf_signature
    begin
      sign_piece if DocumentTools.correct_pdf_if_needed(self.cloud_content_object.path)
    rescue => e
      recreate_pdf
    end
  end

  def sign_piece
    begin
      content_file_path = self.cloud_content_object.path
      to_sign_file = File.dirname(content_file_path) + '/signed.pdf'

      DocumentTools.sign_pdf(content_file_path, to_sign_file)

      if File.exist?(to_sign_file.to_s)
        self.is_signed = true
        self.cloud_content_object.attach(File.open(to_sign_file), self.cloud_content_object.filename) if self.save
      else
        System::Log.info('pieces_events', "[Signing] #{self.id} - #{self.name} - Piece can't be saved or signed file not genereted (#{to_sign_file.to_s})")
        self.is_signed = false
        self.save

        Pack::Piece.delay_for(20.minutes, queue: :low).correct_pdf_signature_of(self.id)

        log_document = {
          subject: "[Pack::Piece] piece can't be saved or signed file not genereted",
          name: "Pack::Piece",
          error_group: "[pack-piece] piece can't be saved or signed file not genereted",
          erreur_type: "Piece can't be saved or signed file not genereted (#{to_sign_file.to_s}",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            validation_model: self.valid?,
            file_to_sign_exist: File.exist?(to_sign_file.to_s),
            file_to_sign: to_sign_file.to_s,
            model: self.inspect,
            user: self.user.inspect,
            method: "sign_piece"
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      end
    rescue => e
      System::Log.info('pieces_events', "[Signing] #{self.id} - #{self.name} - #{e.to_s} (#{to_sign_file.to_s})")
      self.is_signed = false
      self.save

      Pack::Piece.delay_for(2.hours, queue: :low).correct_pdf_signature_of(self.id)

      log_document = {
        subject: "[Pack::Piece] piece signing rescue #{e.message}",
        name: "Pack::Piece",
        error_group: "[pack-piece] piece signing rescue",
        erreur_type: "Piece - Signing rescue",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          validation_model: self.valid?,
          file_to_sign: to_sign_file.to_s,
          model: self.inspect,
          user: self.user.inspect,
          method: "sign_piece",
          error: e.to_s
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end
  end

  def init_tags
    self.tags = pack.name.downcase.sub(' all', '').split

    tags << position if position
  end

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))

      token
    end
  end


  def get_access_url(style = :original)
    "/account/documents/pieces/#{id}/download/#{style}" + '?token=' + get_token
  end


  def journal
    name.split[1]
  end

  def is_deleted?
    self.delete_at.present?
  end

  def scanned?
    origin == 'scan'
  end


  def uploaded?
    origin == 'upload'
  end


  def dematbox_scanned?
    origin == 'dematbox_scan'
  end


  def retrieved?
    origin == 'retriever'
  end

  def from_web?
    temp_document.try(:api_name) == 'web'
  end

  def from_mobile?
    temp_document.try(:api_name) == 'mobile'
  end

  def from_mcf?
    temp_document.try(:api_name) == 'mcf'
  end

  def get_pages_number
    return self.pages_number if self.pages_number > 0

    begin
      self.pages_number = DocumentTools.pages_number(self.cloud_content_object.path)
      save
    rescue
      0
    end
    return self.pages_number
  end

  def is_awaiting_pre_assignment?
    self.pre_assignment_waiting? || self.pre_assignment_force_processing?
  end

  def is_already_pre_assigned_with?(process='preseizure')
    process == 'preseizure' ? preseizures.any? : expense.present?
  end

  def get_state_to(type='image')
    text    = 'none'
    img_url = ''

    if self.pre_assignment_waiting_analytics?
      text    = 'awaiting_analytics'
      img_url = 'application/compta_analytics.png'
    elsif self.is_awaiting_pre_assignment?
      text    = 'awaiting_pre_assignment'
      img_url = 'application/preaff_pending.png'
    elsif self.preseizures.delivered.count > 0
      text    = 'delivered'
      img_url = 'application/preaff_deliv.png'
    elsif self.preseizures.where(is_delivered_to: [nil, ''], delivery_tried_at: [nil, '']).count > 0 && self.user.uses_api_softwares?
      text    = 'delivery_pending'
      img_url = 'application/preaff_deliv_pending.png'
    elsif self.preseizures.failed_delivery.count > 0
      text    = 'delivery_failed'
      img_url = 'application/preaff_err.png'
    elsif Pack::Report::Preseizure.unscoped.where(piece_id: self.id, is_blocked_for_duplication: true).count > 0
      text    = 'duplication'
      img_url = 'application/preaff_dupl.png'
    elsif self.pre_assignment_ignored? || self.pre_assignment_truly_ignored?
      text    = 'piece_ignored'
      img_url = 'application/preaff_ignored.png'
    end

    return text if type.to_s == 'text'
    return img_url
  end

  def get_tags(separator='-')
    filters = self.name.split.collect do |f|
      f.strip.match(/^[0-9]+$/) ? f.strip.to_i.to_s : f.strip.downcase
    end

    _tags = self.tags.present? ? self.tags.select{ |tag| !filters.include?(tag.to_s.strip.downcase) } : []

    _tags.join(" #{separator} ").presence || ''
  end

  private

  def set_number
    self.number = DbaSequence.next('Piece') unless number
  end
end
