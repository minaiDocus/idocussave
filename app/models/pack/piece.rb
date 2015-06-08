# -*- encoding : UTF-8 -*-
class Pack::Piece
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :name
  field :number,                     type: Integer
  field :content_file_name
  field :content_content_type
  field :content_file_size,          type: Integer
  field :content_updated_at,         type: Time
  field :is_a_cover,                 type: Boolean, default: false
  field :origin
  field :position,                   type: Integer
  field :token
  field :is_awaiting_pre_assignment, type: Boolean, default: false
  field :pre_assignment_comment

  index({ number: 1 }, { unique: true })

  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan fiduceo)

  before_validation :set_number

  belongs_to :organization
  belongs_to :user
  belongs_to :pack,                                                  inverse_of: :pieces
  has_one    :temp_document,                                         inverse_of: :piece
  has_one    :expense,       class_name: "Pack::Report::Expense",    inverse_of: :piece
  has_many   :preseizures,   class_name: 'Pack::Report::Preseizure', inverse_of: :piece
  has_many   :remote_files,  as: :remotable, dependent: :destroy
  has_many   :operations,    class_name: 'Operation',                inverse_of: :piece

  has_mongoid_attached_file :content,
                            path: ":rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename",
                            url: "/account/documents/pieces/:id/download"
  do_not_validate_attachment_file_type :content

  scope :scanned,          -> { where(origin: 'scan') }
  scope :uploaded,         -> { where(origin: 'upload') }
  scope :dematbox_scanned, -> { where(origin: 'dematbox_scan') }
  scope :fiduceo,          -> { where(origin: 'fiduceo') }

  scope :covers,     -> { where(is_a_cover: true) }
  scope :not_covers, -> { any_in(is_a_cover: [false, nil]) }

  scope :of_month, -> time { where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

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

private

  def set_number
    self.number = DbaSequence.next('Piece') unless self.number
  end
end
