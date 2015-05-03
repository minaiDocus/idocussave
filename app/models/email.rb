# -*- encoding : UTF-8 -*-
class Email
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  belongs_to :to_user,   class_name: 'User', inverse_of: 'received_emails'
  belongs_to :from_user, class_name: 'User', inverse_of: 'sended_emails'
  has_many :temp_documents

  field :message_id
  field :originally_created_at, type: Time
  field :to
  field :from
  field :subject
  field :attachment_names,      type: Array,   default: []
  field :size,                  type: Integer, default: 0
  field :state,                                default: 'created'
  field :errors_list,           type: Array,   default: []
  field :is_error_notified,     type: Boolean, default: false

  validates_uniqueness_of :message_id

  field :original_content_file_name
  field :original_content_content_type
  field :original_content_file_size,    type: Integer
  field :original_content_updated_at,   type: Time

  has_mongoid_attached_file :original_content,
                            path: ":rails_root/files/:rails_env/:class/:attachment/:filename",
                            url: "/admin/emailed_documents/:id"
  do_not_validate_attachment_file_type :original_content

  scope :created,       where(state: 'created')
  scope :error,         where(state: 'error')
  scope :processed,     where(state: 'processed')
  scope :unprocessable, where(state: 'unprocessable')

  def code
    to.split('@')[0]
  end

  state_machine :initial => :created do
    state :created
    state :error
    state :processed
    state :unprocessable

    event :error do
      transition :created => :error
    end

    event :success do
      transition [:created, :error] => :processed
    end

    event :failure do
      transition [:created, :error] => :unprocessable
    end
  end
end
