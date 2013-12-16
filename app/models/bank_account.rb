# -*- encoding : UTF-8 -*-
class BankAccount
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :service_name

  belongs_to :user

  before_save :upcase_journal

  field :fiduceo_id
  field :bank_name
  field :number
  field :journal
  field :accounting_number, default: '512000'

  index :number, unique: true

  validates_presence_of :number, :journal, :accounting_number
  validates_uniqueness_of :number
  validates_length_of :journal, within: 2..6
  validates_format_of :journal, with: /\A[A-Za-z0-9]*\Z/

private

  def upcase_journal
    self.journal = self.journal.upcase if journal_changed?
  end
end
