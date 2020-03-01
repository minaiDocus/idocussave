# -*- encoding : UTF-8 -*-
class Email < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_original_content' => '/admin/emailed_documents/:id'}

  serialize :errors_list
  serialize :attachment_names


  has_many :temp_documents

  belongs_to :to_user,   class_name: 'User', inverse_of: 'received_emails'
  belongs_to :from_user, class_name: 'User', inverse_of: 'sended_emails'

  validates_uniqueness_of :message_id

  has_one_attached :cloud_original_content

  has_attached_file :original_content,
                            path: ':rails_root/files/:rails_env/:class/:attachment/:filename',
                            url: '/admin/emailed_documents/:id'
  do_not_validate_attachment_file_type :original_content

  before_create :initialize_serialized_attributes

  before_destroy do |email|
    email.cloud_original_content.purge
  end

  scope :error,         -> { where(state: 'error') }
  scope :created,       -> { where(state: 'created') }
  scope :processed,     -> { where(state: 'processed') }
  scope :unprocessable, -> { where(state: 'unprocessable') }


  state_machine initial: :created do
    state :error
    state :created
    state :rejected
    state :processed
    state :unprocessable

    event :error do
      transition created: :error
    end

    event :success do
      transition [:created, :error] => :processed
    end

    event :failure do
      transition [:created, :error] => :unprocessable
    end

    event :reject do
      transition [:created, :error] => :rejected
    end
  end

  def cloud_original_content_object
    CustomActiveStorageObject.new(self, :cloud_original_content)
  end

  def code
    to.split('@')[0]
  end

  def self.search(contains)
    emailed_documents = Email.all

    if contains[:user_contains] && contains[:user_contains][:code].present?
      user = User.where(code: contains[:user_contains][:code]).first

      emailed_documents = emailed_documents.where("to_user_id IN (?) OR from_user_id IN (?)", user.id, user.id) if user
    end

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        emailed_documents = emailed_documents.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    emailed_documents = emailed_documents.where(state: contains[:state])                      unless contains[:state].blank?
    emailed_documents = emailed_documents.where("`from` LIKE ?", "%#{contains[:from]}%")      unless contains[:from].blank?
    emailed_documents = emailed_documents.where("`to` LIKE ?", "%#{contains[:to]}%")          unless contains[:to].blank?
    emailed_documents = emailed_documents.where( "subject LIKE ?", "%#{contains[:subject]}%") unless contains[:subject].blank?
    emailed_documents
  end


  private


  def initialize_serialized_attributes
    self.errors_list      ||= []
    self.attachment_names ||= []
  end
end
