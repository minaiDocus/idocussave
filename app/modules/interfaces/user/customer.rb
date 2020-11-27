module Interfaces::User::Customer
  def active?
    !inactive?
  end

  def inactive?
    inactive_at.present?
  end

  def still_active?
    active? || inactive_at.to_date > Date.today.end_of_month
  end

  def uses_many_exportable_softwares?
    softwares_count = 0
    softwares_count += 1 if uses_coala?
    softwares_count += 1 if uses_quadratus?
    softwares_count += 1 if uses_csv_descriptor?

    softwares_count > 1
  end

  def uses_api_softwares?
    uses_ibiza? || uses_exact_online? || my_unisoft.try(:user_used)
  end

  def uses_non_api_softwares?
    uses_coala? || uses_quadratus? || uses_cegid? || uses_csv_descriptor? || uses_fec_agiris?
  end

  def uses_ibiza?
    self.try(:softwares).try(:is_ibiza_used) && self.organization.try(:ibiza).try(:used?)
  end

  def uses_exact_online?
    self.try(:softwares).try(:is_exact_online_used) && self.organization.is_exact_online_used
  end

  def uses_coala?
    self.try(:softwares).try(:is_coala_used) && self.organization.is_coala_used
  end

  def uses_cegid?
    self.try(:softwares).try(:is_cegid_used) && self.organization.is_cegid_used
  end

  def uses_quadratus?
    self.try(:softwares).try(:is_quadratus_used) && self.organization.is_quadratus_used
  end

  def uses_csv_descriptor?
    self.try(:softwares).try(:is_csv_descriptor_used) && self.organization.is_csv_descriptor_used
  end

  def uses_ibiza_analytics?
    uses_ibiza? && self.ibiza_id.present? && self.try(:softwares).try(:ibiza_compta_analysis_activated?)
  end

  def uses_fec_agiris?
    self.try(:softwares).try(:is_fec_agiris_used) && self.organization.is_fec_agiris_used
  end

  def validate_ibiza_analytics?
    uses_ibiza_analytics? && self.try(:softwares).try(:ibiza_analysis_to_validate?)
  end

  def uses_manual_delivery?
    ( uses_ibiza? && !self.try(:softwares).try(:ibiza_auto_deliver?) ) ||
    ( uses_exact_online? && !self.try(:softwares).try(:exact_online_auto_deliver?) )
  end

  def uses_my_unisoft?
    my_unisoft.present?
  end
end