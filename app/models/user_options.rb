# -*- encoding : UTF-8 -*-
class UserOptions < ApplicationRecord
  belongs_to :user

  PRESEIZURE_DATE_OPTIONS = ['operation_date', 'operation_value_date'].freeze
  DASHBOARD_SUMMARIES = ['last_scans', 'last_uploads', 'last_dematbox_scans', 'last_retrieved'].freeze

  validates_inclusion_of :is_pre_assignment_date_computed, in: [-1, 0, 1]
  validates_inclusion_of :is_operation_processing_forced,  in: [-1, 0, 1]
  validates_inclusion_of :is_operation_value_date_needed,  in: [-1, 0, 1]
  validates_inclusion_of :dashboard_default_summary,       in: DASHBOARD_SUMMARIES

  def pre_assignment_date_computed?
    if is_pre_assignment_date_computed == -1
      user.organization.try(:is_pre_assignment_date_computed)
    else
      is_pre_assignment_date_computed == 1
    end
  end

  # -1 means we refer to organization
  # 0 means normal operation processing
  # 1 means force operation processing
  def operation_processing_forced?
    if is_operation_processing_forced == -1
      user.organization.try(:is_operation_processing_forced)
    else
      is_operation_processing_forced == 1
    end
  end

  # -1 means we refer to organization
  # Else we refer to the index value of PRESEIZURE_DATE_OPTIONS
  def get_preseizure_date_option
    if preseizure_date_option == -1
      UserOptions::PRESEIZURE_DATE_OPTIONS[user.organization.try(:preseizure_date_option)]
    else
      UserOptions::PRESEIZURE_DATE_OPTIONS[preseizure_date_option]
    end
  end

  def operation_value_date_needed?
    if is_operation_value_date_needed == -1
      user.organization.try(:is_operation_value_date_needed)
    else
      is_operation_value_date_needed == 1
    end
  end

  def upload_authorized?
    is_upload_authorized
  end

  def retriever_authorized?
    is_retriever_authorized
  end

  def active_summary
    list = []
    list += %w(last_scans last_uploads) if user.is_prescriber || is_upload_authorized
    list << 'last_dematbox_scans' if user.is_prescriber || user.is_dematbox_authorized
    list << 'last_retrieved' if user.is_prescriber || is_retriever_authorized
    list
  end

  def dashboard_summary
    return @dashboard_summary if @dashboard_summary

    list = active_summary
    @dashboard_summary = if dashboard_default_summary.in? list
      dashboard_default_summary
    else
      choice = list.first
      update(dashboard_default_summary: choice)
      choice
    end
    @dashboard_summary
  end

  def banking_provider
    if user.organization
      default_banking_provider.present? ? default_banking_provider : user.organization.banking_provider
    else
      default_banking_provider.present? ? default_banking_provider : 'budget_insight'
    end
  end
end
