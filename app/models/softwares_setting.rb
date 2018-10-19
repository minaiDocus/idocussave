# -*- encoding : UTF-8 -*-
class SoftwaresSetting < ActiveRecord::Base
  belongs_to :user

  validates_inclusion_of :is_ibiza_auto_deliver,                 in: [-1, 0, 1]
  validates_inclusion_of :is_ibiza_compta_analysis_activated,    in: [-1, 0, 1]
  validates_inclusion_of :is_coala_auto_deliver,                 in: [-1, 0, 1]
  validates_inclusion_of :is_quadratus_auto_deliver,             in: [-1, 0, 1]
  validates_inclusion_of :is_csv_descriptor_auto_deliver,        in: [-1, 0, 1]
  validates_inclusion_of :is_exact_online_auto_deliver,          in: [-1, 0, 1]

  # -1 means we refer to organization
  # 0 means manuel deliver
  # 1 means auto deliver
  def ibiza_auto_deliver?
    if is_ibiza_auto_deliver == -1
      user.organization.try(:ibiza).try(:is_auto_deliver)
    else
      is_ibiza_auto_deliver == 1
    end
  end

  def ibiza_compta_analysis_activated?
    if is_ibiza_compta_analysis_activated == -1
      user.organization.try(:ibiza).try(:is_analysis_activated)
    else
      is_ibiza_compta_analysis_activated == 1
    end
  end

  # -1 means we refer to organization
  # 0 means manuel deliver
  # 1 means auto deliver
  def coala_auto_deliver?
    if is_coala_auto_deliver == -1
      user.organization.try(:is_coala_auto_deliver)
    else
      is_coala_auto_deliver == 1
    end
  end

  # -1 means we refer to organization
  # 0 means manuel deliver
  # 1 means auto deliver
  def quadratus_auto_deliver?
    if is_quadratus_auto_deliver == -1
      user.organization.try(:is_quadratus_auto_deliver)
    else
      is_quadratus_auto_deliver == 1
    end
  end


  # -1 means we refer to organization
  # 0 means manuel deliver
  # 1 means auto deliver
  def csv_descriptor_auto_deliver?
    if is_csv_descriptor_auto_deliver == -1
      user.organization.try(:is_csv_descriptor_auto_deliver)
    else
      is_csv_descriptor_auto_deliver == 1
    end
  end

  # -1 means we refer to organization
  # 0 means manuel deliver
  # 1 means auto deliver
  def exact_online_auto_deliver?
    if is_exact_online_auto_deliver == -1
      user.organization.try(:exact_online).try(:is_auto_deliver)
    else
      is_exact_online_auto_deliver == 1
    end
  end
end
