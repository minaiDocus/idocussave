class Delivery::Queue
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :pack
  referenced_in :user

  field :counter,        type: Integer, default: 0
  field :start_position, type: Integer, default: 0
  field :is_locked,      type: Boolean, default: false

  scope :not_processed, where: { :counter.gt => 0 }
  scope :free,          where: { is_locked: false }
  scope :locked,        where: { is_locked: true }

  validates_presence_of :pack_id, :user_id

  def inc_counter
    self.safely.inc(:counter, 1)
  end

  def inc_counter!
    inc_counter
    save
  end

  def dec_counter
    self.safely.inc(:counter, -1)
  end

  def dec_counter!
    dec_counter
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

  def self.process(id)
    Delivery::Queue.find(id).process!
  end

  def run_on_background
    Delivery::Queue.delay(queue: 'delivery', priority: 5).process(self.id)
  end

  def process!
    piecespath = []
    pieces = pack.pieces.where(:position.gte => self.start_position).by_position
    pieces.each do |piece|
      piecespath << piece.content.path
    end

    filepath = pack.original_document.content.path
    info_path = Pack.info_path(pack.name.gsub(' ','_'),user)
    user.find_or_create_efs.deliver(piecespath + [filepath], info_path)
    
    if user.is_prescriber and user.is_dropbox_extended_authorized and user.dropbox_delivery_folder.present?
      DropboxExtended.deliver(piecespath + [filepath], user.dropbox_delivery_folder, info_path)
    end

    self.start_position = pieces.last.position + 1 rescue self.start_position
    dec_counter
    unlock
    save
  end
end
