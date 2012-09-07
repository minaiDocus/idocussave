class Delivery::Queue
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :pack
  referenced_in :user

  field :counter, type: Integer, default: 0
  field :is_locked, type: Boolean, default: false

  scope :not_processed, where: { :counter.gt => 0 }
  scope :free, where: { is_locked: false }
  scope :locked, where: { is_locked: true }

  def inc
    safely.inc(:counter, 1)
  end

  def inc!
    inc
    save
  end

  def dec
    safely.inc(:counter, -1)
  end

  def dec!
    dec
    save
  end

  def lock
    self.is_locked = true
  end

  def lock!
    lock
    save
  end

  def unlock
    self.is_locked = false
  end

  def unlock!
    unlock
    save
  end

  def self.unlock_all
    Delivery::Queue.each do |e|
      e.unlock!
    end
  end

  def self.run
    Delivery::Queue.not_processed.free.each do |e|
      e.lock!
      e.run_on_background
    end
  end

  def run_on_background
    Delivery::Queue.delay(queue: 'delivery', priority: 5).process(self.id)
  end

  def process(id)
    queue = Delviery::Queue.find(id)
    filespath = []
    queue.pack.pieces.not_delivered.each do |piece|
      filespath << piece.to_file.path
    end
    filespath << pack.original_document.content.path

    info_path = Pack.info_path(pack.name,user)

    user.find_or_create_efs.deliver(filespath, info_path)
    if user.is_prescriber and user.is_dropbox_extended_authorized and user.dropbox_delivery_folder.present?
      DropboxExtended.deliver(filespath, user.dropbox_delivery_folder, info_path)
    end
    clean_up_temp_pdf(filespath)
    queue.dec!
    queue.unlock!
  end

  def clean_up_temp_pdf(filespath)
    filespath.each do |filepath|
      File.delete(filepath)
    end
  end
end
