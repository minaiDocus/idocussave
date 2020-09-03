# -*- encoding : UTF-8 -*-
class PreAssignmentExport < ApplicationRecord
  belongs_to :user
  belongs_to :report, class_name: 'Pack::Report'
  belongs_to :organization

  has_and_belongs_to_many :preseizures, class_name: 'Pack::Report::Preseizure'

  validates_presence_of   :pack_name, :state
  validates_inclusion_of  :for, in: %w(ibiza coala cegid quadratus csv_descriptor)

  scope :not_notified, -> { where(is_notified: false, state: 'generated') }

  state_machine initial: :processing do
    state :generated
    state :error
    state :processing

    event :processing do
      transition any: :processing
    end

    event :generated do
      transition processing: :generated
    end

    event :error do
      transition processing: :error
    end
  end

  def base_path
    Rails.root.join('files', 'exports', self.organization.code.gsub(/[%]/, '_'), self.user.code.gsub(/[%]/, '_'), self.report.period)
  end

  def path
    self.user.uses_many_exportable_softwares? ? base_path.join(self.for) : base_path
  end

  def file_path
    "#{path}/#{self.file_name}"
  end

  def got_error(error, airbrake_notify = true)
    self.error
    self.error_message = error.message.to_s
    self.save
  end

  def got_success(file_name)
    self.generated
    self.file_name = file_name
    self.save
  end
end