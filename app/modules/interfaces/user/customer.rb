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
    softwares_count += 1 if uses?(:coala)
    softwares_count += 1 if uses?(:quadratus)
    softwares_count += 1 if uses?(:csv_descriptor)

    softwares_count > 1
  end


  def uses_api_softwares?
    uses?(:ibiza) || uses?(:exact_online) || uses?(:my_unisoft)
  end


  def uses_non_api_softwares?
    uses?(:coala) || uses?(:quadratus) || uses?(:cegid) || uses?(:csv_descriptor) || use_to(:fec_agiris)
  end


  def uses?(software)
    self.try(software).try(:used?) && self.organization.try(software).try(:used?)
  end


  def uses_ibiza_analytics?
    uses?(:ibiza) && self.try(:ibiza).ibiza_id.present? && self.try(:ibiza).try(:compta_analysis_activated?)
  end


  def validate_ibiza_analytics?
    uses_ibiza_analytics? && self.try(:ibiza).try(:analysis_to_validate?)
  end


  def uses_manual_delivery?
    ( uses?(:ibiza) && !self.try(:ibiza).try(:auto_deliver?) ) ||
    ( uses?(:exact_online) && !self.try(:exact_online).try(:auto_deliver?) )
  end

end
