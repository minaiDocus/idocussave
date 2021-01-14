module Interfaces::Software::IbizaSetting
  def compta_analysis_activated?
    (owner.is_a?(User) && is_analysis_activated == -1) ? self.owner.organization.compta_analysis_activated?(self) : (is_analysis_activated == 1)
  end

  # def uses_analytics?
  #   used? && ibiza_id.present? && is_analysis_activated?
  # end

  def ibiza_id?
    ibiza_id.present?
  end

  def analysis_to_validate?
    (owner.is_a?(User) && is_analysis_to_validate == -1) ? self.owner.organization.analysis_to_validate?(self) : (is_analysis_to_validate == 1)
  end

  def auto_update_accounting_plan?
    is_auto_updating_accounting_plan
  end
end