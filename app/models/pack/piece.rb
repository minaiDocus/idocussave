# -*- encoding : UTF-8 -*-
class Pack::Piece < ActiveRecord::Base
  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan retriever)

  before_validation :set_number



  has_one    :expense, class_name: 'Pack::Report::Expense', inverse_of: :piece
  has_one    :temp_document, inverse_of: :piece

  has_many   :operations,    class_name: 'Operation', inverse_of: :piece
  has_many   :preseizures,   class_name: 'Pack::Report::Preseizure', inverse_of: :piece
  has_many   :remote_files,  as: :remotable, dependent: :destroy

  belongs_to :user
  belongs_to :pack, inverse_of: :pieces
  belongs_to :organization
  belongs_to :analytic_reference, inverse_of: :pieces

  has_attached_file :content,
                            path: ':rails_root/files/:rails_env/:class/:attachment/:mongo_id_or_id/:style/:filename',
                            url: '/account/documents/pieces/:id/download'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  scope :covers,           -> { where(is_a_cover: true) }
  scope :scanned,          -> { where(origin: 'scan') }
  scope :retrieved,        -> { where(origin: 'retriever') }
  scope :of_month,         -> (time) { where('created_at > ? AND created_at < ?', time.beginning_of_month, time.end_of_month) }
  scope :uploaded,         -> { where(origin: 'upload') }
  scope :not_covers,       -> { where(is_a_cover: [false, nil]) }
  scope :by_position,      -> { order(position: :asc) }
  scope :dematbox_scanned, -> { where(origin: 'dematbox_scan') }


  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))

      token
    end
  end


  def get_access_url
    content.url + '&token=' + get_token
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


  def retrieved?
    origin == 'retriever'
  end


  private


  def set_number
    self.number = DbaSequence.next('Piece') unless number
  end
end
