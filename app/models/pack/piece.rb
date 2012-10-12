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
  references_one :preseizure, class_name: "Pack::Report::Preseizure", inverse_of: :piece

  has_mongoid_attached_file :content

  scope :uploaded, where: { is_an_upload: true }
  scope :scanned,  where: { is_an_upload: false }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  before_create :send_to_compta

  def self.by_position
    asc(:position)
  end

  def send_to_compta
    account_book = name.split(' ')[1]
    account_book_type = self.pack.owner.account_book_types.where(name: account_book).first rescue nil
    if account_book_type && account_book_type.compta_processable?
      compta_type = account_book_type.compta_type
      path = File.join([Compta::ROOT_DIR,'input',Time.now.strftime('%Y%m%d'),compta_type])
      filename = ''
      if compta_type == 'CB'
        filename = self.name.gsub(' ','_') + '_' + account_book_type.account_number + '_' + account_book_type.charge_account + '.pdf'
      else
        filename = self.name.gsub(' ','_') + '.pdf'
      end
      FileUtils.mkdir_p(path)
      content_path = (self.content.queued_for_write[:original].presence || self.content).path
      FileUtils.cp(content_path, File.join([path,filename]))
    end
  end
end
