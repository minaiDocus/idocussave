class McfDocument < ApplicationRecord
  RETAKE_RETRY = 3
  RETAKE_TIME  = 10.minutes 

  belongs_to :user

  scope :to_retake,                       -> { where(state: 'needs_retake') }
  scope :processed_but_not_moved,         -> { where("state = 'processed' AND is_moved = false") }
  scope :to_process,                      -> { where(state: 'ready') }
  scope :not_delivered_and_not_notified,  -> { where("state = 'not_delivered' AND is_notified = false") }
  scope :not_processable,                 -> { where("state = 'not_processable' AND is_generated = true") }
  scope :not_processable_and_not_notified,-> { where("state = 'not_processable' AND is_notified = false") }

  state_machine initial: :ready do
    state :ready
    state :processing
    state :processed
    state :not_processable
    state :not_delivered
    state :needs_retake

    after_transition on: :needs_retake do |mcf_doc, _transition|
      mcf_doc.update(retake_at: Time.now + RETAKE_TIME)
    end

    event :processing do
      transition ready: :processing
    end

    event :processed do
      transition processing: :processed
    end

    event :unprocessable do
      transition processing: :not_processable
    end

    event :needs_retake do
      transition processing: :needs_retake
    end

    event :delivery_fails do
      transition needs_retake: :not_delivered
    end
  end

  def self.create_or_initialize_with(params)
    user = User.find_by_code(params[:code])
    if(user)
      mcf_doc = McfDocument.find_by_access_token(params[:access_token])

      if mcf_doc
        mcf_doc.update(params)
        mcf_doc.is_generated = false
        mcf_doc.is_moved = false
      else
        mcf_doc = McfDocument.create(params)
      end

      mcf_doc.user = user
      mcf_doc.state = 'ready'

      mcf_doc.save
    end
    mcf_doc || nil
  end

  def file64_decoded
    (self.file64.present?)? Base64.decode64(self.file64) : nil
  end

  def file_name
    "MCF_#{code}_#{journal}_#{id}#{File.extname(self.original_file_name)}"
  end

  def is_not_moved
    self.is_moved == false
  end

  def can_retake?
    self.retake_retry <= RETAKE_RETRY && self.needs_retake? && self.retake_at <= Time.now
  end

  def has_retaken
    update(retake_retry: self.retake_retry + 1, retake_at: Time.now + RETAKE_TIME)
  end

  def maximum_retake_reach?
    self.retake_retry > RETAKE_RETRY
  end
  
  def got_error(error=nil)
    self.unprocessable
    update(error_message: error)
  end

  def reset
    self.state = 'ready'
    self.is_generated = false
    self.error_message = nil
    self.save
  end
end