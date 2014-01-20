# -*- encoding : UTF-8 -*-
class Pack::Piece
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :name
  field :content_file_name
  field :content_content_type
  field :content_file_size,          type: Integer
  field :content_updated_at,         type: Time
  field :is_a_cover,                 type: Boolean, default: false
  field :origin
  field :position,                   type: Integer
  field :token
  field :is_awaiting_pre_assignment, type: Boolean, default: false

  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan fiduceo)

  belongs_to :pack,                                                 inverse_of: :pieces
  has_one    :expense,      class_name: "Pack::Report::Expense",    inverse_of: :piece
  has_many   :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :piece
  has_many   :remote_files, as: :remotable, dependent: :destroy

  has_mongoid_attached_file :content,
                            path: ":rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename",
                            url: "/account/documents/pieces/:id/download"

  scope :scanned,          where: { origin: 'scan' }
  scope :uploaded,         where: { origin: 'upload' }
  scope :dematbox_scanned, where: { origin: 'dematbox_scan' }
  scope :fiduceo,          where: { origin: 'fiduceo' }
  
  scope :covers,     where:  { is_a_cover: true }
  scope :not_covers, any_in: { is_a_cover: [false, nil] }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  before_create :send_to_compta

  def self.by_position
    asc(:position)
  end

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))
      token
    end
  end

  def get_access_url
    content.url + "&token=" + get_token
  end

  def journal
    name.split[1]
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

  def fiduceo?
    origin == 'fiduceo'
  end

  def send_to_compta
    account_book = name.split(' ')[1]
    account_book_type = self.pack.owner.account_book_types.where(name: account_book).first rescue nil
    if account_book_type && account_book_type.compta_processable? && !self.is_a_cover
      compta_type = account_book_type.compta_type
      if fiduceo?
        path = File.join([Compta::ROOT_DIR,'input',Time.now.strftime('%Y%m%d'),'fiduceo',compta_type])
      else
        path = File.join([Compta::ROOT_DIR,'input',Time.now.strftime('%Y%m%d'),compta_type])
      end
      FileUtils.mkdir_p(path)
      filename = DocumentTools.file_name(self.name)
      content_path = (self.content.queued_for_write[:original].presence || self.content).path
      FileUtils.cp(content_path, File.join([path,filename]))
      self.is_awaiting_pre_assignment = true
      self.save if persisted?
    end
  end
end
