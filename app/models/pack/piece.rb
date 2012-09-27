# -*- encoding : UTF-8 -*-
class Pack::Piece
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :name,               type: String
  field :content_file_name
  field :content_file_type
  field :content_file_size,  type: Integer
  field :content_updated_at, type: Time
  field :is_an_upload,       type: Boolean, default: false
  field :position,           type: Integer

  referenced_in :pack, inverse_of: :pieces
  references_one :expense, class_name: "Pack::Report::Expense", inverse_of: :piece

  has_mongoid_attached_file :content

  scope :uploaded, where: { is_an_upload: true }
  scope :scanned,  where: { is_an_upload: false }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  before_create :send_to_presaisie

  def self.by_position
    asc(:position)
  end

  private

  def send_to_presaisie
    account_book = name.split(' ')[1]
    account_book_type = self.pack.owner.account_book_types.where(name: account_book).first rescue nil
    if account_book_type && account_book_type.presaisie_processable?
      presaisie_type = account_book_type.presaisie_type
      path = File.join([PreSaisie::ROOT_DIR,'input',Time.now.strftime('%Y%m%d'),presaisie_type])
      filename = self.name.gsub(' ','_') + '.pdf'
      FileUtils.mkdir_p(path)
      FileUtils.cp(self.content.queued_for_write[:original].path, File.join([path,filename]))
    end
  end
end
