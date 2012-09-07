class Delivery::Error
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :user
  referenced_in :pack

  field :sender, type: String
  field :state, type: String
  field :filepath, type: String
  field :message, type: String
  field :number, type: Integer
  field :is_resolved, type: Boolean, default: false

  before_create :set_number

  scope :resolved,   where: { is_resolved: true }
  scope :unresolved, where: { is_resolved: false }
  scope :old,        where: { :created_at.lt => 1.month.ago }

  def self.by_number
    asc(:number)
  end

  def self.clean_old_resolved
    self.old.resolved.destroy_all
  end

  def self.clean_old_unresolved
    self.old.unresolved.destroy_all
  end

  def to_s
    "#{number} - #{self.created_at} : #{self.sender} on #{self.state}\n\t#{self.filename} -> #{self.filepath}\n\t#{self.message}"
  end

  def filename
    File.basename(self.filepath)
  end

  def filebasename
    File.basename(self.filepath,'.pdf')
  end

  def path
    File.dirname(self.filepath)
  end

  def file
    piece = pack.pieces.where(name: filebasename).first
    if piece
      piece.to_file
    else
      Rails.logger.warn 'Piece not found'
      nil
    end
  end

  def resolved!
    update_attribute(:is_resolved, true)
  end

  def resend!
    result = send_file
    if result
      resolved!
    else
      result
    end
  end

  def efs
    user.external_file_storage
  end

  private

  def set_number
    self.number = DbaSequence.next('Delivery::ErrorStack')
  end

  def send_file
    current_file = file
    if file
      begin
        if self.sender == 'DropboxExtended'
          send_to_dropbox_e(current_file)
        elsif self.sender == 'DropboxBasic'
          send_to_dropbox_b(current_file)
        elsif self.sender == 'GoogleDrive'
          send_to_google_drive(current_file)
        elsif self.sender == 'FTP'
          send_to_ftp(current_file)
        else
          false
        end
        File.delete(file.path)
      rescue => e
        Rails.logger.warn e
      end
    else
      nil
    end
  end

  def send_to_dropbox_e(file_obj)
    @client ||= DropboxExtended.get_client(DropboxExtended.get_session)
    @client.put_file(self.filepath,file_obj)
  end

  def send_to_dropbox_b(file_obj)
    @client ||= efs.dropbox_basic.client
    @client.put_file(self.filepath, file_obj, overwrite=true)
  end

  def send_to_google_drive(file_obj)
    @client ||= efs.google_doc.client
    collection = @client.find_or_create_collection(path)
    if collection
      @client.update_or_create_file(file_obj.path, collection['id'].split('/')[-1], 'application/pdf', collection)
    end
  end

  def send_to_ftp(file_obj)
    @client = efs.ftp.client
    efs.ftp.change_or_make_dir(path, @client)
    @client.put(file_obj.path)
    @client.close
  end
end
